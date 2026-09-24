import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:rootcause_qr_inspector/core/performance/cancellation_token.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/file_inspection_coordinator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Una página de PDF ya rasterizada a un PNG temporal.
///
/// [imagePath] apunta a un archivo del directorio temporal del sistema que
/// `PdfPageRenderer.cleanup` debe eliminar en cuanto termine el análisis.
class RenderedPdfPage {
  const RenderedPdfPage({required this.pageNumber, required this.imagePath});

  final int pageNumber;
  final String imagePath;
}

/// Rasterized pages plus the real document size, so truncation is never
/// silent in the user interface.
class PdfRenderBatch {
  const PdfRenderBatch({
    required this.pages,
    required this.totalPages,
    required this.inspectedPages,
    required this.selected,
  });

  const PdfRenderBatch.cancelled()
    : pages = const <RenderedPdfPage>[],
      totalPages = 0,
      inspectedPages = 0,
      selected = false;

  final List<RenderedPdfPage> pages;
  final int totalPages;
  final int inspectedPages;
  final bool selected;
  bool get truncated => totalPages > inspectedPages;
}

/// Rasteriza páginas de un PDF para buscar códigos en ellas.
///
/// Solo existe en plataformas con `dart:io`; la variante stub lanza
/// `UnsupportedError`, que es lo que ocurre en la demo web.
///
/// Controles de recursos, todos deliberados:
/// - como máximo 50 páginas por documento;
/// - escala adaptativa y acotada para que una página normal alcance unos
///   4096 px en su lado mayor, preservando barras y QR pequeños;
/// - cada imagen de página se libera en cuanto se escribe en disco;
/// - la cancelación se propaga al renderizador nativo, no solo al bucle;
/// - ante cualquier error se limpian los archivos ya escritos y el directorio
///   temporal antes de relanzar.
class PdfPageRenderer {
  static Future<PdfRenderBatch> pickAndRender({
    int maxPages = FileInspectionLimits.maxPdfPages,
    CancellationToken? cancellationToken,
    void Function(int current, int total)? onProgress,
    void Function(int totalPages, int inspectedPages)? onDocumentOpened,
  }) async {
    await pdfrxFlutterInitialize();
    final PlatformFile? selection = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
    );
    final String? path = selection?.path;
    if (path == null || path.isEmpty) return const PdfRenderBatch.cancelled();
    final File input = File(path);
    if (!FileInspectionInputValidator.isAllowedFileSize(await input.length())) {
      throw const FormatException('El PDF supera el límite local de 50 MiB.');
    }
    final RandomAccessFile headerFile = await input.open();
    try {
      final List<int> header = await headerFile.read(5);
      if (header.length < 5 || String.fromCharCodes(header) != '%PDF-') {
        throw const FormatException(
          'El archivo seleccionado no contiene una cabecera PDF válida.',
        );
      }
    } finally {
      await headerFile.close();
    }

    final PdfDocument document = await PdfDocument.openFile(path);
    final Directory temporaryDirectory = await getTemporaryDirectory();
    final Directory outputDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}rcqr_pdf_${DateTime.now().microsecondsSinceEpoch}',
    );
    await outputDirectory.create(recursive: true);

    final List<RenderedPdfPage> rendered = <RenderedPdfPage>[];
    try {
      final int count = FileInspectionInputValidator.pdfPagesToInspect(
        document.pages.length,
        maxPages: maxPages,
      );
      onDocumentOpened?.call(document.pages.length, count);
      for (int index = 0; index < count; index++) {
        cancellationToken?.throwIfCancelled();
        onProgress?.call(index + 1, count);
        final PdfPage page = document.pages[index];
        final double scale = FileInspectionInputValidator.pdfRasterScale(
          page.width,
          page.height,
        );
        final PdfPageRenderCancellationToken renderToken = page
            .createCancellationToken();
        void cancelRender() {
          if (cancellationToken?.isCancelled ?? false) renderToken.cancel();
        }

        cancellationToken?.addListener(cancelRender);
        cancelRender();
        final PdfImage? pdfImage;
        try {
          pdfImage = await page.render(
            fullWidth: page.width * scale,
            fullHeight: page.height * scale,
            backgroundColor: 0xFFFFFFFF,
            cancellationToken: renderToken,
          );
        } finally {
          cancellationToken?.removeListener(cancelRender);
        }
        cancellationToken?.throwIfCancelled();
        if (pdfImage == null) continue;
        try {
          final ui.Image image = await pdfImage.createImage();
          try {
            final ByteData? byteData = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (byteData == null) continue;
            final String outputPath =
                '${outputDirectory.path}${Platform.pathSeparator}page_${index + 1}.png';
            await File(
              outputPath,
            ).writeAsBytes(byteData.buffer.asUint8List(), flush: true);
            rendered.add(
              RenderedPdfPage(pageNumber: index + 1, imagePath: outputPath),
            );
          } finally {
            image.dispose();
          }
        } finally {
          pdfImage.dispose();
        }
      }
      if (rendered.isEmpty && await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
      return PdfRenderBatch(
        pages: List<RenderedPdfPage>.unmodifiable(rendered),
        totalPages: document.pages.length,
        inspectedPages: count,
        selected: true,
      );
    } catch (_) {
      await cleanup(rendered);
      if (await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
      rethrow;
    } finally {
      await document.dispose();
    }
  }

  static Future<void> cleanup(Iterable<RenderedPdfPage> pages) async {
    final Set<String> directories = <String>{};
    for (final RenderedPdfPage page in pages) {
      final File file = File(page.imagePath);
      directories.add(file.parent.path);
      if (await file.exists()) await file.delete();
    }
    for (final String path in directories) {
      final Directory directory = Directory(path);
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }
}
