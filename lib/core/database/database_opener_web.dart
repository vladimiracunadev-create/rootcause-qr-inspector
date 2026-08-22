import 'package:sembast_web/sembast_web.dart';

Future<Database> openScannerDatabase() {
  return databaseFactoryWeb.openDatabase('rootcause_qr_inspector_v2.db', version: 2);
}
