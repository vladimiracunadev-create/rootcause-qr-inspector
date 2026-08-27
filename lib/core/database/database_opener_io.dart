import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Abre la base en el directorio de soporte de la aplicación.
///
/// El nombre del archivo lleva el sufijo `_v2` porque coexiste con la base de
/// la generación anterior heredada del lector universal.
Future<Database> openScannerDatabase() async {
  final Directory directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final String path = '${directory.path}${Platform.pathSeparator}rootcause_qr_inspector_v2.db';
  return databaseFactoryIo.openDatabase(path, version: 2);
}
