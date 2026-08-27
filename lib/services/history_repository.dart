import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rootcause_qr_inspector/core/database/app_database.dart';
import 'package:rootcause_qr_inspector/core/recovery/recovery_issue.dart';
import 'package:rootcause_qr_inspector/core/recovery/recovery_repository.dart';
import 'package:rootcause_qr_inspector/core/security/payload_cipher.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

/// Resultado de la conversión del historial heredado guardado en preferencias.
///
/// `completed == false` no significa pérdida: la fuente original y su respaldo
/// cifrado siguen intactos, y la pantalla de ajustes ofrece reintentar.
class HistoryMigrationStatus {
  const HistoryMigrationStatus({required this.completed, this.migrated = 0, this.errorCode, this.backupPresent = false});
  final bool completed;
  final int migrated;
  final String? errorCode;
  final bool backupPresent;
}

/// Persistencia del historial: metadatos en claro, carga siempre cifrada.
///
/// Cada registro del almacén `scan_history` guarda tres campos: `id`,
/// `scannedAt` —necesario para ordenar y podar sin descifrar— y `payload`, el
/// sobre AES-256-GCM con el `ScanRecord` completo.
///
/// Comportamientos que sostienen el contrato de datos:
///
/// - un registro que no se puede descifrar **no se borra**: se aísla como
///   incidencia de recuperación con su sobre original, y el resto del historial
///   sigue cargando;
/// - los sobres antiguos se actualizan de forma perezosa, al leerlos;
/// - [maxItems] limita el historial a 5000 registros y el recorte elimina
///   siempre los más antiguos;
/// - la conversión desde `scan_history_v1` guarda antes un respaldo cifrado del
///   origen exacto, verifica dentro de la transacción que todo lo esperado
///   quedó escrito y solo entonces borra la clave antigua.
///
/// Riesgo al modificarla: cualquier atajo que elimine el origen heredado antes
/// de verificar la escritura reintroduce una migración destructiva.
class HistoryRepository {
  HistoryRepository(this._database, this._cipher, {RecoveryRepository? recovery})
      : _recovery = recovery ?? RecoveryRepository(_database);

  static const String _legacyStorageKey = 'scan_history_v1';
  static const String _legacyBackupKey = 'scan_history_v1_backup';
  static const String _migrationKey = 'history_migrated_to_v2';
  static const String _migrationErrorKey = 'history_migration_error';
  static const int maxItems = 5000;

  final AppDatabase _database;
  final PayloadCipher _cipher;
  final RecoveryRepository _recovery;
  final StoreRef<String, Map<String, Object?>> _store = stringMapStoreFactory.store('scan_history');
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<HistoryMigrationStatus> initialize() => _migrateLegacyHistory();

  Future<List<ScanRecord>> load({int limit = maxItems}) async {
    final List<RecordSnapshot<String, Map<String, Object?>>> snapshots = await _store.find(
      _database.database,
      finder: Finder(sortOrders: <SortOrder>[SortOrder('scannedAt', false)], limit: limit),
    );
    final List<ScanRecord> result = <ScanRecord>[];
    for (final RecordSnapshot<String, Map<String, Object?>> snapshot in snapshots) {
      final String? encrypted = snapshot.value['payload'] as String?;
      if (encrypted == null) {
        await _recovery.record(
          entityType: RecoveryEntityType.history,
          entityId: snapshot.key,
          code: 'missing_payload',
        );
        continue;
      }
      try {
        result.add(ScanRecord.fromJson(await _cipher.decryptJson(encrypted)));
        final CipherEnvelopeInfo info = _cipher.inspect(encrypted);
        if (info.legacy || info.version < PayloadCipher.currentVersion) {
          await _store.record(snapshot.key).update(_database.database, <String, Object?>{
            'payload': await _cipher.upgradeEnvelope(encrypted),
          });
        }
      } on Object catch (error) {
        await _recovery.record(
          entityType: RecoveryEntityType.history,
          entityId: snapshot.key,
          code: 'decrypt_${error.runtimeType}',
          encryptedPayload: encrypted,
        );
      }
    }
    return result;
  }

  Future<void> upsert(ScanRecord record) async {
    await _store.record(record.id).put(_database.database, <String, Object?>{
      'id': record.id,
      'scannedAt': record.scannedAt.toUtc().toIso8601String(),
      'payload': await _cipher.encryptJson(record.toJson()),
    });
    await _trim();
  }

  Future<void> upsertAll(Iterable<ScanRecord> records) async {
    final List<MapEntry<ScanRecord, String>> encrypted = <MapEntry<ScanRecord, String>>[];
    for (final ScanRecord record in records) {
      encrypted.add(MapEntry<ScanRecord, String>(record, await _cipher.encryptJson(record.toJson())));
    }
    await _database.database.transaction((Transaction transaction) async {
      for (final MapEntry<ScanRecord, String> entry in encrypted) {
        await _store.record(entry.key.id).put(transaction, <String, Object?>{
          'id': entry.key.id,
          'scannedAt': entry.key.scannedAt.toUtc().toIso8601String(),
          'payload': entry.value,
        });
      }
    });
    await _trim();
  }

  Future<void> replaceAll(Iterable<ScanRecord> records) async {
    final List<MapEntry<ScanRecord, String>> encrypted = <MapEntry<ScanRecord, String>>[];
    for (final ScanRecord record in records) {
      encrypted.add(MapEntry<ScanRecord, String>(record, await _cipher.encryptJson(record.toJson())));
    }
    await _database.database.transaction((Transaction transaction) async {
      await _store.delete(transaction);
      for (final MapEntry<ScanRecord, String> entry in encrypted) {
        await _store.record(entry.key.id).put(transaction, <String, Object?>{
          'id': entry.key.id,
          'scannedAt': entry.key.scannedAt.toUtc().toIso8601String(),
          'payload': entry.value,
        });
      }
    });
  }

  Future<Set<String>> ids() async {
    final List<RecordSnapshot<String, Map<String, Object?>>> records = await _store.find(_database.database);
    return records.map((RecordSnapshot<String, Map<String, Object?>> item) => item.key).toSet();
  }

  Future<void> remove(String id) => _store.record(id).delete(_database.database);

  Future<void> pruneOlderThan(int days) async {
    if (days <= 0) return;
    final String cutoff =
        DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();
    final List<RecordSnapshot<String, Map<String, Object?>>> expired = await _store.find(
      _database.database,
      finder: Finder(filter: Filter.lessThan('scannedAt', cutoff)),
    );
    if (expired.isEmpty) return;
    await _database.database.transaction((Transaction transaction) async {
      for (final RecordSnapshot<String, Map<String, Object?>> snapshot in expired) {
        await _store.record(snapshot.key).delete(transaction);
      }
    });
  }

  Future<void> clear() => _store.delete(_database.database);

  Future<void> _trim() async {
    final int count = await _store.count(_database.database);
    if (count <= maxItems) return;
    final List<RecordSnapshot<String, Map<String, Object?>>> old = await _store.find(
      _database.database,
      finder: Finder(sortOrders: <SortOrder>[SortOrder('scannedAt')], limit: count - maxItems),
    );
    await _database.database.transaction((Transaction transaction) async {
      for (final RecordSnapshot<String, Map<String, Object?>> snapshot in old) {
        await _store.record(snapshot.key).delete(transaction);
      }
    });
  }

  Future<void> _migrateRecordsAtomically(List<ScanRecord> records) async {
    final Set<String> before = await ids();
    final Set<String> expected = <String>{...before, ...records.map((ScanRecord item) => item.id)};
    if (expected.length > maxItems) throw StateError('migration_limit_exceeded');

    final List<MapEntry<ScanRecord, String>> encrypted = <MapEntry<ScanRecord, String>>[];
    for (final ScanRecord record in records) {
      encrypted.add(MapEntry<ScanRecord, String>(record, await _cipher.encryptJson(record.toJson())));
    }

    await _database.database.transaction((Transaction transaction) async {
      for (final MapEntry<ScanRecord, String> entry in encrypted) {
        await _store.record(entry.key.id).put(transaction, <String, Object?>{
          'id': entry.key.id,
          'scannedAt': entry.key.scannedAt.toUtc().toIso8601String(),
          'payload': entry.value,
        });
      }
      final List<RecordSnapshot<String, Map<String, Object?>>> stored = await _store.find(transaction);
      final Set<String> actual = stored.map((RecordSnapshot<String, Map<String, Object?>> item) => item.key).toSet();
      if (!actual.containsAll(expected)) throw StateError('migration_verification_failed');
    });
  }

  Future<HistoryMigrationStatus> _migrateLegacyHistory() async {
    if (await _preferences.getBool(_migrationKey) ?? false) {
      return HistoryMigrationStatus(
        completed: true,
        backupPresent: (await _preferences.getString(_legacyBackupKey) ?? '').isNotEmpty,
      );
    }
    final String? stored = await _preferences.getString(_legacyStorageKey);
    if (stored == null || stored.isEmpty) {
      await _preferences.setBool(_migrationKey, true);
      return const HistoryMigrationStatus(completed: true);
    }

    try {
      // Preserve the exact legacy source, but never duplicate it in clear text.
      final String encryptedBackup = await _cipher.encryptJson(<String, Object?>{
        'schemaVersion': 1,
        'encoding': 'utf8-base64',
        'raw': base64Encode(utf8.encode(stored)),
      });
      await _preferences.setString(_legacyBackupKey, encryptedBackup);

      final dynamic decoded = jsonDecode(stored);
      if (decoded is! List) throw const FormatException('legacy_not_list');
      final List<ScanRecord> records = decoded
          .map<ScanRecord>((dynamic item) => ScanRecord.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
      await _migrateRecordsAtomically(records);

      await _preferences.remove(_legacyStorageKey);
      await _preferences.remove(_migrationErrorKey);
      await _preferences.setBool(_migrationKey, true);
      return HistoryMigrationStatus(completed: true, migrated: records.length, backupPresent: true);
    } on Object catch (error) {
      final String code = 'legacy_${error.runtimeType}';
      await _preferences.setString(_migrationErrorKey, code);
      await _recovery.record(
        entityType: RecoveryEntityType.migration,
        entityId: 'history_v1_to_v2',
        code: code,
      );
      final bool backupPresent = (await _preferences.getString(_legacyBackupKey) ?? '').isNotEmpty;
      return HistoryMigrationStatus(completed: false, errorCode: code, backupPresent: backupPresent);
    }
  }
}
