import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometry for a camera preview whose central reading area must never sit
/// underneath the status strip or the camera controls.
@immutable
class ScannerViewportGeometry {
  const ScannerViewportGeometry({
    required this.compact,
    required this.readingArea,
    required this.statusReserve,
    required this.controlsReserve,
    required this.scanWindow,
  });

  /// Calcula el marco a partir del tamaño real de la vista previa.
  ///
  /// Reserva primero el alto de la barra de estado y el de los controles, y solo
  /// después dimensiona el cuadrado. Por eso el marco nunca queda debajo de un
  /// botón, ni siquiera en una pantalla corta: `compact` reduce las reservas en
  /// lugar de permitir que el área útil se vuelva negativa.
  ///
  /// [readingArea] es la amplitud elegida por la persona con el gesto de
  /// pellizco: 0 es el encuadre mínimo y 1 el máximo. A partir de
  /// [maximizedThreshold] la pantalla retira el encabezado y la vista previa
  /// ocupa toda la pestaña; en ese modo la reserva superior crece, porque la
  /// entrada por archivo pasa a la esquina superior derecha y el marco no puede
  /// quedar debajo de ella.
  factory ScannerViewportGeometry.forSize(Size size, {double readingArea = 0}) {
    final double area = readingArea.clamp(0.0, 1.0);
    final bool compact = size.height < 520 || size.width < 360;
    final double statusReserve = isMaximized(area)
        ? (compact ? 104 : 120)
        : (compact ? 68 : 80);
    final double controlsReserve = compact ? 124 : 144;
    final double usableHeight = math.max(
      40,
      size.height - statusReserve - controlsReserve,
    );
    final double widthFactor = _lerp(
      compact ? 0.64 : 0.72,
      compact ? 0.86 : 0.94,
      area,
    );
    final double heightFactor = _lerp(0.92, 1, area);
    final double side = math.max(
      40,
      math.min(size.width * widthFactor, usableHeight * heightFactor),
    );

    return ScannerViewportGeometry(
      compact: compact,
      readingArea: area,
      statusReserve: statusReserve,
      controlsReserve: controlsReserve,
      scanWindow: Rect.fromCenter(
        center: Offset(size.width / 2, statusReserve + usableHeight / 2),
        width: side,
        height: side,
      ),
    );
  }

  /// Amplitud a partir de la cual la vista previa ocupa toda la pestaña.
  ///
  /// No es 1 exacto: el gesto de pellizco rara vez termina en el extremo justo,
  /// y obligar a clavarlo convertiría «pantalla completa» en algo que casi
  /// nunca se alcanza.
  static const double maximizedThreshold = 0.85;

  static bool isMaximized(double readingArea) =>
      readingArea.clamp(0.0, 1.0) >= maximizedThreshold;

  /// Amplitud resultante de un pellizco en curso.
  ///
  /// [start] es la amplitud al apoyar los dedos y [scale] la escala que informa
  /// el gesto, que vale 1 al empezar. El recorrido es **logarítmico**, y eso no
  /// es una elegancia: la escala de un pellizco es multiplicativa —es el
  /// cociente entre la distancia actual y la inicial— y restarle 1 la trata
  /// como si fuera lineal. Con esa resta se podía maximizar de un gesto
  /// (separar los dedos multiplica la distancia sin techo) pero **no minimizar**
  /// de un gesto: juntarlos nunca baja de 0, así que la escala no podía restar
  /// más de 1 y volver del máximo al mínimo exigía varios intentos. Lo detectó
  /// el pellizco real en el emulador.
  ///
  /// Con el logaritmo las dos direcciones son simétricas: cuadruplicar la
  /// distancia recorre todo el rango hacia arriba, y reducirla a la cuarta
  /// parte lo recorre hacia abajo.
  ///
  /// Es aritmética pura y vive aquí —no en la pantalla— para poder comprobarla
  /// sin cámara.
  static double pinchedReadingArea({
    required double start,
    required double scale,
  }) {
    final double from = start.clamp(0.0, 1.0);
    // Una escala nula o negativa no describe ninguna distancia: el gesto no
    // mueve nada en lugar de producir un logaritmo infinito.
    if (scale <= 0) return from;
    final double octaves = math.log(scale) / math.ln2;
    return (from + octaves * _pinchGain).clamp(0.0, 1.0);
  }

  /// Cuánto recorre el rango duplicar la distancia entre los dedos.
  ///
  /// 0,5 significa que hacen falta dos duplicaciones —cuadruplicar— para ir del
  /// encuadre mínimo a la pantalla completa. Menos que eso vuelve el gesto
  /// nervioso; más, interminable.
  static const double _pinchGain = 0.5;

  /// Porcentaje que se muestra durante el gesto.
  ///
  /// El mínimo se declara como 50 % y el máximo como 100 %: un 0 % diría «sin
  /// zona de lectura», que es justo lo que no ocurre: el encuadre mínimo sigue
  /// cubriendo la mitad de la imagen.
  static int percentageFor(double readingArea) =>
      (50 + readingArea.clamp(0.0, 1.0) * 50).round();

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;

  final bool compact;

  /// Amplitud elegida, de 0 (mínima) a 1 (pantalla completa).
  final double readingArea;

  final double statusReserve;
  final double controlsReserve;
  final Rect scanWindow;

  /// True cuando la vista previa debe ocupar toda la pestaña.
  bool get maximized => isMaximized(readingArea);

  /// Porcentaje mostrado a la persona para esta amplitud.
  int get percentage => percentageFor(readingArea);
}
