import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometry for a camera preview whose central reading area must never sit
/// underneath the status strip or the camera controls.
@immutable
class ScannerViewportGeometry {
  const ScannerViewportGeometry({
    required this.compact,
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
  factory ScannerViewportGeometry.forSize(Size size) {
    final bool compact = size.height < 520 || size.width < 360;
    final double statusReserve = compact ? 68 : 80;
    final double controlsReserve = compact ? 124 : 144;
    final double usableHeight = math.max(40, size.height - statusReserve - controlsReserve);
    final double side = math.max(
      40,
      math.min(
        size.width * (compact ? 0.64 : 0.72),
        usableHeight * 0.92,
      ),
    );

    return ScannerViewportGeometry(
      compact: compact,
      statusReserve: statusReserve,
      controlsReserve: controlsReserve,
      scanWindow: Rect.fromCenter(
        center: Offset(size.width / 2, statusReserve + usableHeight / 2),
        width: side,
        height: side,
      ),
    );
  }

  final bool compact;
  final double statusReserve;
  final double controlsReserve;
  final Rect scanWindow;
}
