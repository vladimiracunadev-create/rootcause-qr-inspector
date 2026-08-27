import 'dart:async';

import 'package:flutter/services.dart';

/// Copia al portapapeles con borrado programado.
///
/// El temporizador comprueba el contenido antes de limpiarlo: si el usuario ya
/// copió otra cosa, no se le borra. `clearAfterSeconds <= 0` desactiva el
/// borrado, que es lo que significa la opción «Nunca» de los ajustes.
///
/// Límite conocido: el temporizador vive en el proceso. Si la aplicación se
/// cierra antes de que expire, el valor permanece en el portapapeles.
abstract final class ClipboardService {
  static Future<void> copy(String value, {int clearAfterSeconds = 30}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (clearAfterSeconds <= 0) return;
    Timer(Duration(seconds: clearAfterSeconds), () async {
      final ClipboardData? current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) await Clipboard.setData(const ClipboardData(text: ''));
    });
  }
}
