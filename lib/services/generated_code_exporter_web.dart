import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> exportGeneratedCode({
  required Uint8List bytes,
  required String mimeType,
  required String fileName,
  required String title,
}) async {
  final web.Blob blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Give the browser a turn to consume the object URL before releasing it.
  await Future<void>.delayed(Duration.zero);
  web.URL.revokeObjectURL(url);
}
