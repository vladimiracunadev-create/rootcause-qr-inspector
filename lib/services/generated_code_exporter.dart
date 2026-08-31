import 'dart:typed_data';

import 'generated_code_exporter_native.dart'
    if (dart.library.html) 'generated_code_exporter_web.dart'
    as platform;

/// Exports a generated barcode using the interaction expected on each host.
///
/// Browsers download the bytes directly. Android and iOS keep the native share
/// sheet so the image can be saved, sent or opened by another application.
Future<void> exportGeneratedCode({
  required Uint8List bytes,
  required String mimeType,
  required String fileName,
  required String title,
}) {
  return platform.exportGeneratedCode(
    bytes: bytes,
    mimeType: mimeType,
    fileName: fileName,
    title: title,
  );
}
