import 'package:rootcause_qr_inspector/core/investigation/unicode_confusables_data.dart';

/// Esqueleto de confusión de UTS #39, reducido a lo que suplanta en latín.
///
/// El motor ya detectaba **mezcla** de escrituras: una `о` cirílica dentro de
/// una palabra latina. Lo que no detectaba es el caso contrario y más limpio:
/// un host escrito **entero** en una sola escritura no latina que se lee como
/// una marca latina. `раураl.example` no mezcla nada —es cirílico de principio
/// a fin— y hasta ahora solo producía `host-unicode`, el hallazgo de confianza
/// baja que también dispara un dominio internacional legítimo.
///
/// El esqueleto sustituye cada carácter por su equivalente ASCII declarado por
/// Unicode. Si un host no ASCII se convierte así en ASCII puro, está escrito
/// para leerse como otra cosa.
///
/// Alcance declarado, para que nadie lo confunda con UTS #39 completo:
///
/// - solo se aplican las equivalencias **cuyo destino es ASCII**;
/// - **no** se normaliza a NFD, porque Dart no trae normalización Unicode: un
///   carácter precompuesto que no esté en la tabla se queda como está;
/// - el latín con diacríticos —`café`, `piñón`— **no** se considera confuso.
///   Es escritura legítima del idioma, y tratarla como engaño convertiría media
///   internet hispanohablante en sospechosa.
abstract final class UnicodeSkeleton {
  /// Esqueleto del valor: equivalencias ASCII aplicadas y todo en minúsculas.
  static String of(String value) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in value.runes) {
      final String? replacement = kConfusableAsciiMap[rune];
      if (replacement != null) {
        buffer.write(replacement);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString().toLowerCase();
  }

  /// Esqueleto reducido a letras y dígitos, para comparar con un token.
  ///
  /// Así `раураl`, `pay-pal` y `PayPal` llegan al mismo valor comparable y un
  /// token de marca deja de poder esquivarse cambiando la escritura.
  static String comparable(String value) =>
      of(value).replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Si el host está escrito en otra escritura pero se lee como ASCII.
  ///
  /// Exige las dos condiciones a la vez: que el esqueleto sea ASCII puro y que
  /// al menos un carácter venga de una escritura no latina. Con solo la primera
  /// condición, un `café.example` escrito con `é` pasaría por suplantación; con
  /// solo la segunda, cualquier dominio internacional legítimo lo haría.
  static bool isWholeScriptConfusable(String host) {
    if (host.isEmpty) return false;
    if (isAsciiHost(host)) return false;
    if (!isAsciiHost(of(host))) return false;
    return host.runes.any(
      (int rune) =>
          rune > 127 &&
          !_isLatinScript(rune) &&
          kConfusableAsciiMap.containsKey(rune),
    );
  }

  /// Si el valor solo usa caracteres válidos de un host ASCII.
  static bool isAsciiHost(String value) =>
      RegExp(r'^[a-z0-9.\-_]+$').hasMatch(value.toLowerCase());

  /// Rangos latinos, incluidos los suplementos con diacríticos.
  ///
  /// Una `é` o una `ẽ` son latín: pertenecen al idioma, no al engaño.
  static bool _isLatinScript(int rune) =>
      rune <= 0x024F ||
      (rune >= 0x1E00 && rune <= 0x1EFF) ||
      (rune >= 0x2C60 && rune <= 0x2C7F) ||
      (rune >= 0xA720 && rune <= 0xA7FF);
}
