import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometría del visor del inventario, que cuenta unidades en serie.
///
/// Es distinta de la del inspector por una razón de uso: aquí la cámara
/// comparte la pantalla con la lista de unidades contadas, así que ampliar la
/// zona de lectura significa **crecer el visor y ceder sitio a la lista**, no
/// ocupar la pestaña entera. El marco, además, es un rectángulo ancho: en un
/// inventario lo normal es un código de barras lineal, no un QR cuadrado.
@immutable
class InventoryViewportGeometry {
  const InventoryViewportGeometry({
    required this.readingArea,
    required this.previewHeight,
    required this.frame,
  });

  /// Calcula el alto del visor y el marco que va dentro.
  ///
  /// [availableHeight] es el alto de la pantalla: de él sale el techo del
  /// visor, para que al ampliar no se coma la lista de unidades ni desborde la
  /// columna. [readingArea] es la misma preferencia que usa el inspector, así
  /// que un pellizco en cualquiera de las dos pantallas deja a la otra con el
  /// mismo encuadre.
  factory InventoryViewportGeometry.forPreview({
    required double availableHeight,
    required double previewWidth,
    double readingArea = 0,
  }) {
    final double area = readingArea.clamp(0.0, 1.0);
    final double previewHeight = previewHeightFor(
      availableHeight: availableHeight,
      readingArea: area,
    );
    // La barra de estado del inventario vive abajo, dentro del visor: el marco
    // se centra en la banda que queda por encima para no quedar debajo de ella,
    // como ocurría con el marco fijo.
    final double usableHeight = math.max(60, previewHeight - statusReserve);
    final double width = math.max(
      math.min(180, previewWidth),
      math.min(
        previewWidth * 0.9,
        _lerp(math.min(260, previewWidth * 0.8), previewWidth * 0.9, area),
      ),
    );
    // El tercer límite es el que mantiene la forma: sin él, en una pantalla
    // grande el marco crecía más de alto que de ancho y dejaba de parecer lo
    // que es, la banda donde entra un código de barras lineal.
    final double height = math.min(
      math.min(
        _lerp(minFrameHeight, usableHeight * 0.82, area),
        usableHeight * 0.86,
      ),
      width * 0.62,
    );

    return InventoryViewportGeometry(
      readingArea: area,
      previewHeight: previewHeight,
      frame: Rect.fromCenter(
        center: Offset(previewWidth / 2, usableHeight / 2),
        width: width,
        height: height,
      ),
    );
  }

  /// Alto del visor con la amplitud mínima: el valor histórico de la pantalla.
  static const double minPreviewHeight = 230;

  /// Banda inferior reservada a la barra de estado del inventario.
  static const double statusReserve = 72;

  /// Alto del marco con la amplitud mínima.
  static const double minFrameHeight = 120;

  /// Alto del visor para una amplitud dada.
  ///
  /// Nunca baja de [minPreviewHeight] —la amplitud mínima deja la pantalla tal
  /// como estaba— y nunca pasa del 58 % de la pantalla, porque por debajo del
  /// visor siguen la lista de unidades y la barra de navegación.
  static double previewHeightFor({
    required double availableHeight,
    required double readingArea,
  }) {
    final double area = readingArea.clamp(0.0, 1.0);
    final double ceiling = math.max(minPreviewHeight, availableHeight * 0.58);
    return _lerp(minPreviewHeight, ceiling, area);
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;

  final double readingArea;
  final double previewHeight;
  final Rect frame;
}
