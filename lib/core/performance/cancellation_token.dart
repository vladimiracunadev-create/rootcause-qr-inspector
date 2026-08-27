import 'package:flutter/foundation.dart';

/// Señal de cancelación voluntaria; no es un error que deba reportarse.
///
/// Las pantallas la capturan por separado para distinguir «el usuario canceló»
/// de «el análisis falló», y en ambos casos dejan el historial intacto.
class OperationCancelledException implements Exception {
  const OperationCancelledException();
  @override
  String toString() => 'OperationCancelledException';
}

/// Testigo de cancelación cooperativa para los lotes de imagen y PDF.
///
/// Es cooperativo: el trabajo largo debe llamar a `throwIfCancelled` entre
/// pasos. Al ser un `ChangeNotifier`, también permite propagar la cancelación
/// a un renderizador que ya está en curso, como hace `PdfPageRenderer`.
class CancellationToken extends ChangeNotifier {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    notifyListeners();
  }

  void throwIfCancelled() {
    if (_cancelled) throw const OperationCancelledException();
  }
}

/// Progreso observable de un lote, para el diálogo cancelable.
///
/// `fraction` devuelve `null` mientras no se conoce el total, lo que la barra
/// de progreso interpreta como indeterminada.
class BatchProgress extends ChangeNotifier {
  BatchProgress({this.label = ''});

  String label;
  int current = 0;
  int total = 0;

  double? get fraction => total <= 0 ? null : current / total;

  void update({String? label, int? current, int? total}) {
    if (label != null) this.label = label;
    if (current != null) this.current = current;
    if (total != null) this.total = total;
    notifyListeners();
  }
}
