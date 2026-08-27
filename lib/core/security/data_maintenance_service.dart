import 'package:sembast/sembast.dart';
import 'package:rootcause_qr_inspector/core/database/app_database.dart';
import 'package:rootcause_qr_inspector/core/security/encryption_metadata_repository.dart';
import 'package:rootcause_qr_inspector/core/security/payload_cipher.dart';

/// Recuento de lo que una rotación de llave reencriptó realmente.
class EncryptionRotationResult {
  const EncryptionRotationResult({required this.keyId, required this.historyRecords, required this.inventorySessions});
  final String keyId;
  final int historyRecords;
  final int inventorySessions;
}

/// Rota la llave de cifrado sin exponer ni perder datos.
///
/// El orden importa y es la razón de existir de esta clase:
///
/// 1. se descifra y se vuelve a cifrar **todo** en memoria, con una llave
///    nueva, antes de tocar la base;
/// 2. una única transacción escribe los registros y el identificador de llave
///    activa;
/// 3. si algo falla —un `payload` ausente, un descifrado imposible, la
///    transacción revertida— la llave recién creada se borra del almacén
///    seguro para no dejar material huérfano que después parezca activo.
///
/// Lanza `StateError('encryption_rotation_in_progress')` si se invoca dos
/// veces a la vez, y `history_payload_missing:<id>` o
/// `inventory_payload_missing:<id>` cuando un registro está incompleto.
///
/// Riesgo al modificarla: mover el cifrado dentro de la transacción alargaría
/// el bloqueo de la base sobre operaciones criptográficas y volvería a hacer
/// posible el estado mixto que este diseño evita.
class DataMaintenanceService {
  DataMaintenanceService(this._database, this._cipher, this._metadata);

  final AppDatabase _database;
  final PayloadCipher _cipher;
  final EncryptionMetadataRepository _metadata;
  final StoreRef<String, Map<String, Object?>> _history = stringMapStoreFactory.store('scan_history');
  final StoreRef<String, Map<String, Object?>> _inventory = stringMapStoreFactory.store('inventory_sessions');
  bool _rotationInProgress = false;

  Future<EncryptionRotationResult> rotateEncryptionKey() async {
    if (_rotationInProgress) throw StateError('encryption_rotation_in_progress');
    _rotationInProgress = true;
    final String keyId = 'v3_${DateTime.now().toUtc().millisecondsSinceEpoch}';
    try {
      final List<RecordSnapshot<String, Map<String, Object?>>> history = await _history.find(_database.database);
      final List<RecordSnapshot<String, Map<String, Object?>>> inventory = await _inventory.find(_database.database);
      final Map<String, String> historyPayloads = <String, String>{};
      final Map<String, String> inventoryPayloads = <String, String>{};

      for (final RecordSnapshot<String, Map<String, Object?>> item in history) {
        final String? payload = item.value['payload'] as String?;
        if (payload == null) throw StateError('history_payload_missing:${item.key}');
        historyPayloads[item.key] = await _cipher.encryptJson(await _cipher.decryptJson(payload), keyId: keyId);
      }
      for (final RecordSnapshot<String, Map<String, Object?>> item in inventory) {
        final String? payload = item.value['payload'] as String?;
        if (payload == null) throw StateError('inventory_payload_missing:${item.key}');
        inventoryPayloads[item.key] = await _cipher.encryptJson(await _cipher.decryptJson(payload), keyId: keyId);
      }

      await _database.database.transaction((Transaction transaction) async {
        for (final MapEntry<String, String> entry in historyPayloads.entries) {
          await _history.record(entry.key).update(transaction, <String, Object?>{'payload': entry.value});
        }
        for (final MapEntry<String, String> entry in inventoryPayloads.entries) {
          await _inventory.record(entry.key).update(transaction, <String, Object?>{'payload': entry.value});
        }
        await _metadata.saveActiveKeyId(keyId, transaction: transaction);
      });
      _cipher.activateKey(keyId);
      return EncryptionRotationResult(
        keyId: keyId,
        historyRecords: historyPayloads.length,
        inventorySessions: inventoryPayloads.length,
      );
    } on Object {
      // A failed precomputation or rolled-back transaction must not leave an
      // orphan key that could later be mistaken for an active key.
      try {
        await _cipher.forgetKey(keyId);
      } on Object {
        // Preserve the original rotation error; the unused key is not active.
      }
      rethrow;
    } finally {
      _rotationInProgress = false;
    }
  }
}
