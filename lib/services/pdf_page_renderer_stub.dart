import 'package:rootcause_qr_inspector/core/performance/cancellation_token.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/file_inspection_coordinator.dart';

/// Equivalente de la variante nativa, para que los tipos compilen en web.
class RenderedPdfPage {
  const RenderedPdfPage({required this.pageNumber, required this.imagePath});

  final int pageNumber;
  final String imagePath;
}

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

/// Variante para plataformas sin `dart:io`: declara la ausencia en vez de
/// fallar en silencio.
///
/// La pantalla del escáner ya oculta la opción de PDF cuando `kIsWeb`, así que
/// este `UnsupportedError` es una segunda barrera, no la ruta esperada.
class PdfPageRenderer {
  static Future<PdfRenderBatch> pickAndRender({
    int maxPages = FileInspectionLimits.maxPdfPages,
    CancellationToken? cancellationToken,
    void Function(int current, int total)? onProgress,
    void Function(int totalPages, int inspectedPages)? onDocumentOpened,
  }) {
    throw UnsupportedError(
      'La lectura de PDF no está disponible en esta plataforma.',
    );
  }

  static Future<void> cleanup(Iterable<RenderedPdfPage> pages) async {}
}
