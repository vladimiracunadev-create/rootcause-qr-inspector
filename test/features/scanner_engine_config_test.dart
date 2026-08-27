import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/features/scanner/data/mobile_scanner_engine.dart';

/// Regression guard for the two settings that made the scanner look broken.
///
/// Both are platform configuration, so no test can prove they read a distant
/// QR — only a device can. What these cases do prevent is a silent revert to
/// the values that caused the reports: a camera stuck at the Android default
/// of 640x480, and a detector that refuses to emit the same code twice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the camera is asked for more than the 640x480 Android default', () {
    expect(MobileScannerEngine.inspectionResolution.width, greaterThan(640));
    expect(MobileScannerEngine.inspectionResolution.height, greaterThan(480));
    expect(MobileScannerEngine.inventoryResolution.width, greaterThan(640));
    // Continuous counting reads codes up close and runs for minutes, so it
    // deliberately asks for less than the inspection camera.
    expect(
      MobileScannerEngine.inventoryResolution.width,
      lessThan(MobileScannerEngine.inspectionResolution.width),
    );
  });

  test('the engine hands that resolution and a repeatable detector to the controller', () {
    final MobileScannerEngine engine = MobileScannerEngine(torchEnabled: false);
    addTearDown(MobileScannerController.resetPlatformSessionOwner);

    expect(engine.controller.cameraResolution, MobileScannerEngine.inspectionResolution);
    // `noDuplicates` never emits the same payload twice, so a code presented
    // again after closing its result produced no event at all.
    expect(engine.controller.detectionSpeed, DetectionSpeed.normal);
    expect(engine.controller.autoZoom, isTrue);
    expect(engine.controller.returnImage, isFalse);
  });

  test('an explicit resolution overrides the inspection default', () {
    final MobileScannerEngine engine = MobileScannerEngine(
      torchEnabled: false,
      cameraResolution: MobileScannerEngine.inventoryResolution,
    );
    addTearDown(MobileScannerController.resetPlatformSessionOwner);

    expect(engine.controller.cameraResolution, const Size(1280, 720));
  });
}
