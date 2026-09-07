import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/services/pdf_page_renderer.dart';

void main() {
  test(
    'cleanup elimina imágenes y el directorio temporal tras éxito',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'rcqr-pdf-cleanup-',
      );
      final File first = await File(
        '${directory.path}${Platform.pathSeparator}page_1.png',
      ).writeAsBytes(<int>[1]);
      final File second = await File(
        '${directory.path}${Platform.pathSeparator}page_2.png',
      ).writeAsBytes(<int>[2]);

      await PdfPageRenderer.cleanup(<RenderedPdfPage>[
        RenderedPdfPage(pageNumber: 1, imagePath: first.path),
        RenderedPdfPage(pageNumber: 2, imagePath: second.path),
      ]);

      expect(await directory.exists(), isFalse);
    },
  );

  test('cleanup es idempotente después de excepción o cancelación', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'rcqr-pdf-error-',
    );
    final File page = await File(
      '${directory.path}${Platform.pathSeparator}page_1.png',
    ).writeAsBytes(<int>[1]);
    final List<RenderedPdfPage> pages = <RenderedPdfPage>[
      RenderedPdfPage(pageNumber: 1, imagePath: page.path),
    ];

    await PdfPageRenderer.cleanup(pages);
    await PdfPageRenderer.cleanup(pages);

    expect(await directory.exists(), isFalse);
  });

  test('PdfRenderBatch declara truncación sin ocultar el total', () {
    const PdfRenderBatch batch = PdfRenderBatch(
      pages: <RenderedPdfPage>[],
      totalPages: 120,
      inspectedPages: 50,
      selected: true,
    );

    expect(batch.truncated, isTrue);
    expect(batch.totalPages, 120);
    expect(batch.inspectedPages, 50);
  });
}
