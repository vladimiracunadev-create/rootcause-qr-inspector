import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rootcause_qr_inspector/core/localization/app_localizations.dart';
import 'package:rootcause_qr_inspector/features/scanner/widgets/scanner_viewport_geometry.dart';
import 'package:rootcause_qr_inspector/state/settings_store.dart';

/// Gesto de pellizco que maximiza y minimiza la zona de lectura.
///
/// Vive en un mixin y no en cada pantalla porque la inspección y el inventario
/// deben comportarse igual: el mismo gesto, el mismo porcentaje, la misma
/// preferencia guardada. Dos copias del mismo cálculo acabarían divergiendo en
/// el primer ajuste.
///
/// Reglas que el mixin impone a quien lo usa:
///
/// - **dos dedos.** Un solo dedo sobre la vista previa es el toque de enfoque
///   de la cámara, y un arrastre de un dedo no puede mover el encuadre por
///   accidente;
/// - **se guarda al levantar los dedos**, no en cada cuadro del gesto: escribir
///   en el almacén del sistema mientras se pellizca es un castigo de disco por
///   una decisión que todavía no está tomada;
/// - **la pista se enseña una vez.** Un gesto sin control a la vista no se
///   descubre solo.
mixin ReadingAreaPinchMixin<T extends StatefulWidget> on State<T> {
  /// Preferencias donde vive la amplitud elegida.
  SettingsStore get readingAreaSettings;

  double? _pinchArea;
  double? _pinchStart;
  bool _noticeVisible = false;
  bool _noticeIsHint = false;
  bool _hintShown = false;
  Timer? _noticeTimer;

  /// Amplitud vigente: la del pellizco en curso o, si no hay gesto, la guardada.
  double get readingArea =>
      _pinchArea ?? readingAreaSettings.value.readingAreaScale;

  /// Si la vista previa debe ocupar todo el espacio disponible.
  bool get readingAreaMaximized =>
      ScannerViewportGeometry.isMaximized(readingArea);

  bool get readingAreaNoticeVisible => _noticeVisible;

  /// Si el indicador muestra la pista del gesto en lugar del porcentaje.
  bool get readingAreaNoticeIsHint => _noticeIsHint;

  /// Debe llamarse desde `dispose` de la pantalla.
  void disposeReadingAreaPinch() => _noticeTimer?.cancel();

  void onReadingAreaScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    final double current = readingArea;
    setState(() {
      _pinchStart = current;
      _pinchArea = current;
      _noticeIsHint = false;
    });
    announceReadingArea();
  }

  void onReadingAreaScaleUpdate(ScaleUpdateDetails details) {
    final double? start = _pinchStart;
    if (start == null || details.pointerCount < 2) return;
    final double next = ScannerViewportGeometry.pinchedReadingArea(
      start: start,
      scale: details.scale,
    );
    if (next == _pinchArea) return;
    setState(() => _pinchArea = next);
    announceReadingArea();
  }

  /// Guarda la amplitud al terminar el gesto.
  ///
  /// El valor del pellizco se mantiene en pantalla hasta que la preferencia
  /// está escrita: liberarlo antes haría que el encuadre volviera por un cuadro
  /// al tamaño anterior.
  Future<void> onReadingAreaScaleEnd() async {
    final double? pinched = _pinchArea;
    _pinchStart = null;
    if (pinched == null) return;
    await readingAreaSettings.update(
      readingAreaSettings.value.copyWith(readingAreaScale: pinched),
    );
    if (mounted) setState(() => _pinchArea = null);
  }

  /// Nombra el gesto una sola vez, cuando la cámara arranca de verdad.
  void showReadingAreaHint() {
    if (_hintShown || !mounted) return;
    _hintShown = true;
    setState(() => _noticeIsHint = true);
    announceReadingArea(duration: const Duration(milliseconds: 3600));
  }

  /// Muestra el indicador mientras dura el gesto y poco después.
  void announceReadingArea({
    Duration duration = const Duration(milliseconds: 1600),
  }) {
    _noticeTimer?.cancel();
    _noticeTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _noticeVisible = false;
          _noticeIsHint = false;
        });
      }
    });
    if (!_noticeVisible) setState(() => _noticeVisible = true);
  }
}

/// Porcentaje de la zona de lectura mientras se ajusta con el pellizco.
///
/// Aparece con el gesto y se va solo. Es información de la tarea —cuánto se ha
/// ampliado y si ya se alcanzó el máximo—, no un control: ningún toque sobre él
/// cambia nada, así que no roba gestos a la cámara.
class ReadingAreaBadge extends StatelessWidget {
  const ReadingAreaBadge({
    required this.readingArea,
    required this.hint,
    required this.visible,
    required this.animate,
    super.key,
  });

  final double readingArea;

  /// True cuando el indicador nombra el gesto en lugar del porcentaje.
  final bool hint;

  final bool visible;

  /// False con movimiento reducido: el indicador aparece y desaparece sin
  /// transición en lugar de atenuarse.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final int percentage = ScannerViewportGeometry.percentageFor(readingArea);
    final bool maximized = ScannerViewportGeometry.isMaximized(readingArea);
    final String text = hint
        ? 'Pellizca para ampliar la zona'
        : maximized
        ? 'Zona de lectura $percentage % · máxima'
        : 'Zona de lectura $percentage %';
    final String spoken = hint
        ? 'Pellizca con dos dedos sobre la cámara para ampliar o reducir la zona de lectura'
        : maximized
        ? 'Zona de lectura al $percentage por ciento, la máxima'
        : 'Zona de lectura al $percentage por ciento';
    final Widget badge = IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: spoken,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  hint
                      ? Icons.zoom_out_map
                      : maximized
                      ? Icons.fullscreen
                      : Icons.crop_free,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                AppText(
                  text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!animate) return visible ? badge : const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: badge,
    );
  }
}
