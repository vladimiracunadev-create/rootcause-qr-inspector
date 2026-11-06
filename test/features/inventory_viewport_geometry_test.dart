import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/features/scanner/widgets/inventory_viewport_geometry.dart';

void main() {
  const List<double> amplitudes = <double>[0, 0.25, 0.5, 0.85, 1];
  const List<double> screens = <double>[320, 640, 760, 900, 1180];
  const List<double> widths = <double>[160, 288, 358, 528];

  test('the minimum amplitude leaves the inventory viewer as it was', () {
    for (final double screen in screens) {
      expect(
        InventoryViewportGeometry.previewHeightFor(
          availableHeight: screen,
          readingArea: 0,
        ),
        InventoryViewportGeometry.minPreviewHeight,
      );
    }

    final InventoryViewportGeometry geometry =
        InventoryViewportGeometry.forPreview(
          availableHeight: 760,
          previewWidth: 358,
        );

    // El marco histórico: 120 px de alto y hasta 260 de ancho.
    expect(geometry.frame.height, InventoryViewportGeometry.minFrameHeight);
    expect(geometry.frame.width, 260);
  });

  test('pinching out grows the viewer and never shrinks it', () {
    for (final double screen in screens) {
      double previous = 0;
      for (final double area in amplitudes) {
        final double height = InventoryViewportGeometry.previewHeightFor(
          availableHeight: screen,
          readingArea: area,
        );

        expect(height, greaterThanOrEqualTo(previous));
        expect(
          height,
          greaterThanOrEqualTo(InventoryViewportGeometry.minPreviewHeight),
        );
        // Por debajo del visor siguen la lista de unidades y la navegación.
        expect(
          height,
          lessThanOrEqualTo(
            math.max(InventoryViewportGeometry.minPreviewHeight, screen * 0.58),
          ),
        );
        previous = height;
      }
    }
  });

  test('the frame stays inside the viewer and above its status bar', () {
    for (final double screen in screens) {
      for (final double width in widths) {
        for (final double area in amplitudes) {
          final InventoryViewportGeometry geometry =
              InventoryViewportGeometry.forPreview(
                availableHeight: screen,
                previewWidth: width,
                readingArea: area,
              );

          expect(geometry.frame.left, greaterThanOrEqualTo(0));
          expect(geometry.frame.right, lessThanOrEqualTo(width));
          expect(geometry.frame.top, greaterThanOrEqualTo(0));
          // La barra de estado del inventario vive dentro del visor: el marco
          // fijo anterior se le metía debajo.
          expect(
            geometry.frame.bottom,
            lessThanOrEqualTo(
              geometry.previewHeight - InventoryViewportGeometry.statusReserve,
            ),
          );
          expect(geometry.frame.width, greaterThan(0));
          expect(geometry.frame.height, greaterThan(0));
        }
      }
    }
  });

  test('a wider amplitude also widens the frame', () {
    double previous = 0;
    for (final double area in amplitudes) {
      final InventoryViewportGeometry geometry =
          InventoryViewportGeometry.forPreview(
            availableHeight: 900,
            previewWidth: 358,
            readingArea: area,
          );

      expect(geometry.frame.width, greaterThanOrEqualTo(previous));
      previous = geometry.frame.width;
    }

    // El marco del inventario es un rectángulo ancho: un inventario lee códigos
    // lineales, no QR cuadrados.
    final InventoryViewportGeometry maximized =
        InventoryViewportGeometry.forPreview(
          availableHeight: 900,
          previewWidth: 358,
          readingArea: 1,
        );
    expect(maximized.frame.width, greaterThan(maximized.frame.height));
  });

  test('an out-of-range amplitude is clamped, not trusted', () {
    final InventoryViewportGeometry low = InventoryViewportGeometry.forPreview(
      availableHeight: 760,
      previewWidth: 358,
      readingArea: -4,
    );
    final InventoryViewportGeometry high = InventoryViewportGeometry.forPreview(
      availableHeight: 760,
      previewWidth: 358,
      readingArea: 9,
    );

    expect(low.readingArea, 0);
    expect(low.previewHeight, InventoryViewportGeometry.minPreviewHeight);
    expect(high.readingArea, 1);
    expect(high.previewHeight, 760 * 0.58);
  });
}
