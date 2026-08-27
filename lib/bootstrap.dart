import 'package:rootcause_qr_inspector/core/database/app_database.dart';
import 'package:rootcause_qr_inspector/core/recovery/recovery_repository.dart';
import 'package:rootcause_qr_inspector/core/recovery/recovery_service.dart';
import 'package:rootcause_qr_inspector/core/security/payload_cipher.dart';
import 'package:rootcause_qr_inspector/core/security/encryption_metadata_repository.dart';
import 'package:rootcause_qr_inspector/core/security/data_maintenance_service.dart';
import 'package:rootcause_qr_inspector/services/history_repository.dart';
import 'package:rootcause_qr_inspector/services/inventory_repository.dart';
import 'package:rootcause_qr_inspector/services/settings_repository.dart';
import 'package:rootcause_qr_inspector/state/inventory_store.dart';
import 'package:rootcause_qr_inspector/state/scan_store.dart';
import 'package:rootcause_qr_inspector/state/settings_store.dart';

/// Conjunto de servicios ya inicializados que la interfaz recibe.
///
/// Se construye una sola vez por arranque y se pasa hacia abajo por
/// constructor: el proyecto no usa un contenedor de inyección ni localizadores
/// globales, de modo que las dependencias de cada pantalla son explícitas.
class AppServices {
  const AppServices({
    required this.database,
    required this.scanStore,
    required this.inventoryStore,
    required this.settingsStore,
    required this.recoveryRepository,
    required this.recoveryService,
    required this.dataMaintenanceService,
  });

  final AppDatabase database;
  final ScanStore scanStore;
  final InventoryStore inventoryStore;
  final SettingsStore settingsStore;
  final RecoveryRepository recoveryRepository;
  final RecoveryService recoveryService;
  final DataMaintenanceService dataMaintenanceService;

  bool get temporary => database.temporary;
}

/// Compone la aplicación: base, cifrado, repositorios y stores.
///
/// Orden y motivos:
///
/// 1. abre la base —persistente o en memoria si `temporary`—, lo que también
///    ejecuta las migraciones de esquema;
/// 2. lee el identificador de llave activa desde la base, no desde
///    preferencias, para que coincida con los registros ya escritos;
/// 3. en modo temporal usa un [MemoryEncryptionKeyProvider], así que nada
///    escrito en esa sesión puede recuperarse después;
/// 4. inicializa historial e inventario en paralelo y aplica la retención
///    configurada.
///
/// En modo temporal, un fallo al leer preferencias se ignora deliberadamente:
/// ese modo existe precisamente para arrancar cuando el almacenamiento del
/// sistema no responde. En modo normal ese mismo fallo sí se propaga.
///
/// Cualquier excepción cierra la base antes de relanzar, para no dejar el
/// archivo abierto ante un reintento.
abstract final class AppBootstrapper {
  static Future<AppServices> initialize({bool temporary = false}) async {
    AppDatabase? database;
    try {
      database = temporary ? await AppDatabase.openTemporary() : await AppDatabase.open();
      final RecoveryRepository recovery = RecoveryRepository(database);
      final EncryptionMetadataRepository encryptionMetadata = EncryptionMetadataRepository(database);
      final String activeKeyId = temporary ? PayloadCipher.currentKeyId : await encryptionMetadata.loadActiveKeyId();
      final PayloadCipher cipher = PayloadCipher(
        keyProvider: temporary ? MemoryEncryptionKeyProvider() : null,
        activeKeyId: activeKeyId,
      );
      final SettingsStore settings = SettingsStore(SettingsRepository());
      final ScanStore scans = ScanStore(HistoryRepository(database, cipher, recovery: recovery));
      final InventoryStore inventory = InventoryStore(InventoryRepository(database, cipher, recovery: recovery));

      if (temporary) {
        try {
          await settings.initialize();
        } on Object {
          // Temporary mode remains available even when preferences are unavailable.
        }
      } else {
        await settings.initialize();
      }
      await Future.wait(<Future<void>>[scans.initialize(), inventory.initialize()]);
      await scans.pruneOlderThan(settings.value.historyRetentionDays);
      return AppServices(
        database: database,
        scanStore: scans,
        inventoryStore: inventory,
        settingsStore: settings,
        recoveryRepository: recovery,
        recoveryService: RecoveryService(database, cipher, recovery),
        dataMaintenanceService: DataMaintenanceService(database, cipher, encryptionMetadata),
      );
    } on Object {
      await database?.close();
      rethrow;
    }
  }
}
