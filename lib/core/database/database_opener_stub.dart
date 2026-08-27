import 'package:sembast/sembast.dart';

/// Variante para plataformas sin backend de base: falla de forma explícita.
///
/// El arranque convierte esta excepción en la pantalla de inicio seguro, con
/// la opción de continuar en modo temporal.
Future<Database> openScannerDatabase() {
  throw UnsupportedError('La base de datos no está disponible en esta plataforma.');
}
