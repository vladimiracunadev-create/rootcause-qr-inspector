import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/file_code_decoder.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/scanner_engine.dart';

/// Native local-file decoder backed by the existing scanner engine.
class NativeFileCodeDecoder implements FileCodeDecoder {
  const NativeFileCodeDecoder(this._engine);

  final ScannerEngine _engine;

  @override
  Future<List<Barcode>> decode(String imagePath) async {
    final BarcodeCapture? capture = await _engine.analyzeImage(imagePath);
    return capture?.barcodes ?? const <Barcode>[];
  }
}
