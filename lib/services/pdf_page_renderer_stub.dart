import 'package:rootcause_qr_inspector/core/performance/cancellation_token.dart';

/// Equivalente de la variante nativa, para que los tipos compilen en web.
class RenderedPdfPage {
  const RenderedPdfPage({required this.pageNumber, required this.imagePath});

  final int pageNumber;
  final String imagePath;
}

/// Variante para plataformas sin `dart:io`: declara la ausencia en vez de
/// fallar en silencio.
///
/// La pantalla del escáner ya oculta la opción de PDF cuando `kIsWeb`, así que
/// este `UnsupportedError` es una segunda barrera, no la ruta esperada.
class PdfPageRenderer {
  static Future<List<RenderedPdfPage>> pickAndRender({
    int maxPages = 50,
    CancellationToken? cancellationToken,
    void Function(int current, int total)? onProgress,
  }) {
    throw UnsupportedError('La lectura de PDF no está disponible en esta plataforma.');
  }

  static Future<void> cleanup(Iterable<RenderedPdfPage> pages) async {}
}
