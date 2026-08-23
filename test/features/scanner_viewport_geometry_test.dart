import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/features/scanner/widgets/scanner_viewport_geometry.dart';

void main() {
  void expectClearReadingArea(Size size) {
    final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(size);

    expect(geometry.scanWindow.left, greaterThanOrEqualTo(0));
    expect(geometry.scanWindow.right, lessThanOrEqualTo(size.width));
    expect(geometry.scanWindow.top, greaterThanOrEqualTo(geometry.statusReserve));
    expect(
      geometry.scanWindow.bottom,
      lessThanOrEqualTo(size.height - geometry.controlsReserve),
    );
  }

  test('keeps the QR frame clear on a narrow and short phone preview', () {
    const Size preview = Size(288, 320);

    final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(preview);

    expect(geometry.compact, isTrue);
    expectClearReadingArea(preview);
  });

  test('keeps the QR frame clear on a standard phone preview', () {
    const Size preview = Size(400, 560);

    final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(preview);

    expect(geometry.compact, isFalse);
    expectClearReadingArea(preview);
  });

  test('keeps the QR frame clear on a tall phone preview', () {
    const Size preview = Size(430, 760);

    expectClearReadingArea(preview);
  });
}
