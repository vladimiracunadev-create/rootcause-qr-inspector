import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> exportGeneratedCode({
  required Uint8List bytes,
  required String mimeType,
  required String fileName,
  required String title,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      title: title,
      files: <XFile>[XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: <String>[fileName],
    ),
  );
}
