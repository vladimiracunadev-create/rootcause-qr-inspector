import 'package:sembast/sembast_memory.dart';
import 'package:rootcause_qr_inspector/core/database/database_opener.dart';
import 'package:rootcause_qr_inspector/core/database/schema_migrator.dart';

/// Punto único de apertura de la base local y de su migración de esquema.
///
/// Envuelve una `Database` de Sembast y declara si es persistente o temporal.
/// El backend real lo elige `openScannerDatabase`, resuelto por compilación
/// condicional: archivos en plataformas nativas, IndexedDB en la demo web.
///
/// [AppDatabase.openTemporary] abre una base en memoria con un nombre único
/// por microsegundo. Es la vía de escape del arranque seguro: la aplicación
/// funciona sin tocar —ni poder dañar— los datos persistentes del usuario.
///
/// Toda apertura ejecuta `SchemaMigrator.migrate` antes de devolver la
/// instancia, de modo que ningún repositorio observe un esquema a medio migrar.
class AppDatabase {
  AppDatabase._(this.database, {required this.temporary});

  final Database database;
  final bool temporary;

  static Future<AppDatabase> open() async {
    final AppDatabase result = AppDatabase._(await openScannerDatabase(), temporary: false);
    await SchemaMigrator(result.database).migrate();
    return result;
  }

  static Future<AppDatabase> openTemporary() async {
    final Database database = await databaseFactoryMemory.openDatabase('rcqr_temporary_${DateTime.now().microsecondsSinceEpoch}');
    final AppDatabase result = AppDatabase._(database, temporary: true);
    await SchemaMigrator(database).migrate();
    return result;
  }

  Future<void> close() => database.close();
}
