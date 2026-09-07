import 'package:mobile_scanner/mobile_scanner.dart';

/// Decodes codes from one local raster image without performing any action.
///
/// Native implementations may delegate to the camera package. A future web
/// implementation can use a local browser/WASM decoder without changing the
/// file-inspection workflow.
abstract interface class FileCodeDecoder {
  Future<List<Barcode>> decode(String imagePath);
}
