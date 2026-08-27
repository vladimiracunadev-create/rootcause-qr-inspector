import 'package:sembast_web/sembast_web.dart';

/// Abre la base sobre IndexedDB para el canal de demostración web.
///
/// El almacenamiento del navegador no ofrece las mismas garantías que
/// Keychain/Keystore; la demo web no es una plataforma soportada del producto.
Future<Database> openScannerDatabase() {
  return databaseFactoryWeb.openDatabase('rootcause_qr_inspector_v2.db', version: 2);
}
