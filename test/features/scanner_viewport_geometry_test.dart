import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/features/scanner/widgets/scanner_viewport_geometry.dart';

void main() {
  void expectClearReadingArea(Size size, {double readingArea = 0}) {
    final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(
      size,
      readingArea: readingArea,
    );

    expect(geometry.scanWindow.left, greaterThanOrEqualTo(0));
    expect(geometry.scanWindow.right, lessThanOrEqualTo(size.width));
    expect(
      geometry.scanWindow.top,
      greaterThanOrEqualTo(geometry.statusReserve),
    );
    expect(
      geometry.scanWindow.bottom,
      lessThanOrEqualTo(size.height - geometry.controlsReserve),
    );
  }

  test('keeps the QR frame clear on a narrow and short phone preview', () {
    const Size preview = Size(288, 320);

    final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(
      preview,
    );

    expect(geometry.compact, isTrue);
    expectClearReadingArea(preview);
  });

  test('keeps the QR frame clear on a standard phone preview', () {
    const Size preview = Size(400, 560);

    final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(
      preview,
    );

    expect(geometry.compact, isFalse);
    expectClearReadingArea(preview);
  });

  test('keeps the QR frame clear on a tall phone preview', () {
    const Size preview = Size(430, 760);

    expectClearReadingArea(preview);
  });

  test('pinching out grows the reading frame without ever shrinking it', () {
    const Size preview = Size(400, 760);

    double previous = 0;
    for (final double area in const <double>[0, 0.25, 0.5, 0.75, 1]) {
      final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(
        preview,
        readingArea: area,
      );

      expect(geometry.scanWindow.width, greaterThan(previous));
      expectClearReadingArea(preview, readingArea: area);
      previous = geometry.scanWindow.width;
    }
  });

  test('the frame stays clear at every amplitude on every phone preview', () {
    for (final Size preview in const <Size>[
      Size(288, 320),
      Size(360, 640),
      Size(400, 560),
      Size(430, 900),
    ]) {
      for (final double area in const <double>[0, 0.4, 0.84, 0.85, 1]) {
        expectClearReadingArea(preview, readingArea: area);
      }
    }
  });

  test(
    'full screen starts at the declared threshold, not at the exact end',
    () {
      expect(ScannerViewportGeometry.isMaximized(0.84), isFalse);
      expect(ScannerViewportGeometry.isMaximized(0.85), isTrue);
      expect(ScannerViewportGeometry.isMaximized(1), isTrue);

      final ScannerViewportGeometry maximized = ScannerViewportGeometry.forSize(
        const Size(400, 760),
        readingArea: 1,
      );

      expect(maximized.maximized, isTrue);
      // La reserva superior crece en pantalla completa: ahí vive la entrada por
      // archivo, que el encabezado ya no ofrece.
      expect(maximized.statusReserve, greaterThanOrEqualTo(104));
    },
  );

  test('the percentage reads 50 at the minimum and 100 at the maximum', () {
    expect(ScannerViewportGeometry.percentageFor(0), 50);
    expect(ScannerViewportGeometry.percentageFor(0.5), 75);
    expect(ScannerViewportGeometry.percentageFor(1), 100);
    // Un valor fuera de rango —preferencia corrupta o de otra versión— no
    // produce un porcentaje imposible.
    expect(ScannerViewportGeometry.percentageFor(-3), 50);
    expect(ScannerViewportGeometry.percentageFor(7), 100);
  });

  test('a pinch resolves to an amplitude inside the usable range', () {
    // La escala vale 1 al apoyar los dedos: el encuadre no se mueve solo.
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 0.4, scale: 1),
      0.4,
    );
    // Duplicar la distancia entre los dedos recorre media escala.
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 0, scale: 2),
      closeTo(0.5, 1e-9),
    );
    // Cuadruplicarla recorre el rango completo desde el mínimo.
    expect(ScannerViewportGeometry.pinchedReadingArea(start: 0, scale: 4), 1);
    // Y reducirla a la cuarta parte lo recorre hacia abajo: la misma
    // distancia de gesto en las dos direcciones. Sin esta simetría se podía
    // maximizar de un pellizco pero no minimizar de un pellizco.
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 1, scale: 0.25),
      0,
    );
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 0.6, scale: 0.5),
      closeTo(0.1, 1e-9),
    );
    // Un gesto exagerado se detiene en los extremos, no los sobrepasa.
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 0.9, scale: 64),
      1,
    );
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 0.2, scale: 0.001),
      0,
    );
    // Una escala imposible no mueve el encuadre ni produce un infinito.
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 0.3, scale: 0),
      0.3,
    );
    expect(
      ScannerViewportGeometry.pinchedReadingArea(start: 0.3, scale: -2),
      0.3,
    );
  });

  test('an out-of-range amplitude still produces a usable frame', () {
    const Size preview = Size(400, 760);

    final ScannerViewportGeometry geometry = ScannerViewportGeometry.forSize(
      preview,
      readingArea: 9,
    );

    expect(geometry.readingArea, 1);
    expectClearReadingArea(preview, readingArea: 9);
  });
}
