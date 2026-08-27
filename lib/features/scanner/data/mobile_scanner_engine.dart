import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/scanner_engine.dart';

/// Única implementación de [ScannerEngine].
///
/// La configuración del controlador es deliberada:
/// - `DetectionSpeed.normal` mantiene al motor emitiendo mientras el código
///   siga delante del lente; la repetición se filtra en la pantalla, que sí
///   puede explicarla;
/// - `cameraResolution` se declara de forma explícita porque el valor por
///   defecto de Android —640×480— no alcanza para un código lejano;
/// - `formats: []` pide a la plataforma todas las simbologías disponibles;
/// - `invertImage` permite leer códigos claros sobre fondo oscuro;
/// - `autoZoom` acerca el encuadre cuando el código queda pequeño;
/// - `returnImage: false` impide que la imagen del cuadro entre en memoria o
///   en un resultado exportable, algo innecesario para el análisis local.
class MobileScannerEngine implements ScannerEngine {
  MobileScannerEngine({
    required bool torchEnabled,
    Size cameraResolution = inspectionResolution,
  }) : _controller = MobileScannerController(
          // `noDuplicates` told the platform to emit a value once and never
          // again until a *different* code appeared. As the controller
          // survives stop/start, presenting the same QR after closing its
          // result produced no event at all: the application looked dead. The
          // repetition filter now lives in the screen, where it can also
          // explain itself to the person using it.
          detectionSpeed: DetectionSpeed.normal,
          cameraResolution: cameraResolution,
          formats: const <BarcodeFormat>[],
          invertImage: true,
          autoZoom: true,
          torchEnabled: torchEnabled,
          returnImage: false,
        );

  /// Resolution requested for the inspection camera.
  ///
  /// Android falls back to 640x480 when no resolution is given, and at that
  /// size a QR held at arm's length occupies too few pixels for the decoder
  /// even though the upscaled preview looks perfectly sharp to the person
  /// aiming. That gap — «se ve completo y no hace nada» — is why this value is
  /// explicit. Currently honoured only on Android.
  static const Size inspectionResolution = Size(1920, 1080);

  /// Resolution requested for continuous counting.
  ///
  /// Lower than [inspectionResolution] on purpose: inventory keeps the camera
  /// analysing for minutes, so it trades reach for battery and heat. Codes are
  /// read up close there.
  static const Size inventoryResolution = Size(1280, 720);

  final MobileScannerController _controller;

  @override
  MobileScannerController get controller => _controller;
  @override
  ValueListenable<MobileScannerState> get state => _controller;
  @override
  Future<BarcodeCapture?> analyzeImage(String path) => _controller.analyzeImage(path);
  @override
  Future<void> dispose() => _controller.dispose();
  @override
  Future<void> setZoomScale(double value) => _controller.setZoomScale(value);
  @override
  Future<void> start() => _controller.start();
  @override
  Future<void> stop() => _controller.stop();
  @override
  Future<void> switchCamera() => _controller.switchCamera();
  @override
  Future<void> toggleTorch() => _controller.toggleTorch();
}
