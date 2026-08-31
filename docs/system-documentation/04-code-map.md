# 04 · Mapa completo del código

Inventario jerárquico de todo lo relevante del repositorio. La columna
**Estado** usa cuatro valores: *activo* (participa en el flujo del producto),
*legado* (se conserva por compatibilidad y está declarado como tal),
*experimental* (existe pero está apagado) y *no determinado*.

## Raíz del repositorio

| Ruta | Qué es | Estado |
|---|---|---|
| `pubspec.yaml` · `pubspec.lock` | Manifiesto y resolución fijada de dependencias | Activo |
| `analysis_options.yaml` | `flutter_lints` más cuatro reglas propias | Activo |
| `.fvmrc` | Fija Flutter 3.44.7 | Activo |
| `.gitattributes` | Fuerza LF para que los hashes de `SOURCE_MANIFEST.json` sean verificables tras clonar en Windows | Activo |
| `.gitignore` | Excluye `android/`, `ios/`, `web/`, `macos/` y artefactos | Activo |
| `SOURCE_MANIFEST.json` | SHA-256 y tamaño de cada archivo fuente | Activo |
| `RELEASE_SOURCE.json` | Metadatos de la entrega y qué se validó | Activo |
| `README.md` · `CHANGELOG.md` · `VALIDATION.md` · `IMPLEMENTATION_STATUS.md` | Documentación raíz | Activo |
| `MASTER_PROMPT.md` | Instrucciones de estilo y límites del proyecto | Activo |
| `SECURITY.md` · `CONTRIBUTING.md` · `LICENSE` | Política de seguridad, contribución y licencia MIT | Activo |
| `assets/` | Iconos versionados y el tono `scan_success.wav` | Activo |
| `config/rootcause-qr-policy.example.json` | Política de ejemplo, solo dominios `.example` | Activo · referencia |
| `schemas/rootcause-qr-evidence.schema.json` | JSON Schema 2020-12 de la evidencia | Activo · contrato |
| `fixtures/qr/manifest.json` | 12 casos sintéticos de regresión del motor | Activo |
| `test_assets/` | Imágenes reales de regresión y su manifiesto | Activo |
| `landing/` | Sitio estático publicado en GitHub Pages | Activo · no es la app |
| `build/` | Artefactos y evidencia de ejecuciones anteriores | No versionado |
| `android/` `ios/` `web/` | **No existen en el repositorio**; los genera `tool/bootstrap.py` | Generado |

## `lib/` — arranque

| Archivo | Símbolos | Responsabilidad | Usado por | Estado |
|---|---|---|---|---|
| `main.dart` | `main()` | Instala los capturadores de error y arranca la app dentro de una zona guardada | Punto de entrada | Activo |
| `bootstrap.dart` | `AppServices`, `AppBootstrapper.initialize` | Abre base, cifrado, repositorios y stores en el orden correcto | `BootstrapHost` | Activo |
| `bootstrap_host.dart` | `BootstrapHost`, `_StartupRecovery` | Decide entre la app y la pantalla de inicio seguro | `main` | Activo |
| `app.dart` | `RootCauseQrInspectorApp`, `HandheldFrame`, `BiometricLockGate`, `HomeShell`, `navigationLabelBehaviorForWidth` | Tema, idioma, marco de teléfono, bloqueo y navegación de cinco secciones | `BootstrapHost` | Activo |

## `lib/core/` — infraestructura transversal

### `core/investigation/` — el núcleo del producto

| Archivo | Símbolos principales | Responsabilidad | Depende de | Estado |
|---|---|---|---|---|
| `qr_investigation.dart` | `QrSeverity`, `QrFindingConfidence`, `QrFindingCategory`, `QrActionDecision`, `QrEvidenceFact`, `QrFinding`, `QrInvestigation` | Contrato de datos neutral al idioma, con `toJson`/`fromJson` | Nada externo | Activo |
| `qr_investigation_engine.dart` | `QrInvestigationEngine.analyze` y 14 auxiliares privados | Las 26 reglas, el puntaje, la decisión y las hipótesis | `crypto`, política, `ParsedContent` | Activo |
| `qr_analysis_policy.dart` | `QrTrustedBrand`, `QrAnalysisPolicy` | Umbrales y marcas de la organización | Nada | Activo · sin UI |
| `qr_finding_text.dart` | `QrFindingText.title/explanation/recommendation/evidenceLabel/limitationLabel/severityLabel/actionLabel` | Única capa que traduce ids a español | Contrato | Activo |
| `qr_evidence_exporter.dart` | `QrEvidenceExporter.toMap/toJson/verify` | Paquete forense redactado con checksum canónico | `crypto`, `ScanRecord` | Activo |

### `core/security/`

| Archivo | Símbolos | Responsabilidad | Estado |
|---|---|---|---|
| `payload_cipher.dart` | `EncryptionKeyProvider`, `SecureStorageKeyProvider`, `MemoryEncryptionKeyProvider`, `CipherEnvelopeInfo`, `PayloadCipher` | AES-256-GCM con sobre versionado y llave por identificador | Activo |
| `encryption_metadata_repository.dart` | `EncryptionMetadataRepository` | Guarda la llave activa dentro de la base, no en preferencias | Activo |
| `data_maintenance_service.dart` | `EncryptionRotationResult`, `DataMaintenanceService.rotateEncryptionKey` | Rotación transaccional con limpieza de llave huérfana | Activo |
| `scan_security_analyzer.dart` | `RiskLevel`, `SecurityAssessment`, `ScanSecurityAnalyzer` | Adaptador entre el motor y las pantallas heredadas | **Legado declarado** |

### `core/database/`

| Archivo | Símbolos | Responsabilidad | Estado |
|---|---|---|---|
| `app_database.dart` | `AppDatabase.open/openTemporary/close` | Apertura y migración | Activo |
| `database_opener.dart` | Reexport condicional | Elige backend por plataforma | Activo |
| `database_opener_io.dart` | `openScannerDatabase` | Archivo en el directorio de soporte | Activo |
| `database_opener_web.dart` | `openScannerDatabase` | IndexedDB | Activo · solo demo |
| `database_opener_stub.dart` | `openScannerDatabase` | Lanza `UnsupportedError` | Activo · defensa |
| `schema_migrator.dart` | `SchemaMigrationResult`, `SchemaMigrator` | Cuatro pasos idempotentes en una transacción | Activo |

### `core/recovery/`, `core/performance/`, otros

| Archivo | Símbolos | Responsabilidad | Estado |
|---|---|---|---|
| `recovery/recovery_issue.dart` | `RecoveryEntityType`, `RecoveryIssueState`, `RecoveryIssue` | Incidencia con su sobre cifrado | Activo |
| `recovery/recovery_repository.dart` | `RecoveryRepository.record/load/mark/clearResolved` | Almacén `recovery_issues` con id determinista | Activo |
| `recovery/recovery_service.dart` | `RecoveryService.load/retry/discard/exportBundle` | Acciones sobre registros aislados | Activo |
| `performance/async_write_queue.dart` | `AsyncWriteQueue.run` | Serializa escrituras sin que un fallo envenene la cola | Activo |
| `performance/cancellation_token.dart` | `OperationCancelledException`, `CancellationToken`, `BatchProgress` | Cancelación cooperativa y progreso | Activo |
| `diagnostics/app_diagnostics.dart` | `DiagnosticEntry`, `AppDiagnostics`, `installGlobalErrorHandlers` | Diagnóstico sin cargas ni mensajes | Activo |
| `diagnostics/startup_failure.dart` | `StartupFailure.from` | Fallo de arranque reducido a lo mostrable | Activo |
| `feature_flags/feature_flags.dart` | `FeatureFlags` con nueve banderas | Capacidades futuras apagadas | **Experimental · apagado** |
| `localization/app_localizations.dart` | `AppLocalizations`, `AppStringsContext` | Diez cadenas y el delegado que rechaza inglés | Activo · parcial |
| `theme/app_theme.dart` | `AppTheme.light/dark` | Material 3 con contraste, densidad y movimiento | Activo |
| `utils/barcode_labels.dart` | `BarcodeLabels.format/contentType` | Nombres legibles de simbología y tipo | Activo |
| `app_info.dart` | `appVersion`, `appName` | Único lugar donde se escribe la versión visible | Activo |

## `lib/models/`

| Archivo | Símbolos | Campos clave | Estado |
|---|---|---|---|
| `scan_record.dart` | `ScanRecord` + 3 fábricas + `payloadForBarcode` | `id`, `rawValue`, `parsed`, `investigation`, `riskLevel`, `favorite`, `tags`, `notes` | Activo |
| `parsed_content.dart` | `ContentKind` (17 valores), `ParsedContent` | `kind`, `title`, `fields`, `sensitive` | Activo |
| `app_settings.dart` | `AppLanguage`, `AppSettings` | 17 preferencias más `featureFlags` | Activo |
| `inventory_session.dart` | `InventoryItem`, `InventorySession` | `items` por código, `totalUnits`, `isOpen` | Activo |

## `lib/services/`

| Archivo | Símbolos | Responsabilidad | Estado |
|---|---|---|---|
| `content_interpreter.dart` | `ContentInterpreter.parse` + 12 auxiliares | Interpreta 17 familias de contenido y decide `sensitive` | Activo |
| `history_repository.dart` | `HistoryMigrationStatus`, `HistoryRepository` | Historial cifrado, poda, recorte y migración heredada | Activo |
| `inventory_repository.dart` | `InventoryRepository.load/save/remove` | Sesiones cifradas | Activo |
| `settings_repository.dart` | `SettingsRepository.load/save/resetNonSensitive` | Preferencias | Activo |
| `import_service.dart` | `ImportStrategy`, `HistoryImportPreview`, `InventoryImportPreview`, `ImportService` | Lectura de respaldos como entrada no confiable | Activo |
| `export_service.dart` | `ExportService` con 6 métodos | JSON, CSV y XLSX **sin cifrar** | Activo |
| `scan_feedback.dart` | `ScanTonePlayer`, `AssetScanTonePlayer`, `ScanFeedback` | Tono y vibración con degradación | Activo |
| `clipboard_service.dart` | `ClipboardService.copy` | Copia con borrado programado | Activo |
| `biometric_service.dart` | `BiometricService.isAvailable/authenticate` | Autenticador del sistema | Activo |
| `pdf_page_renderer.dart` | Reexport condicional | Elige implementación | Activo |
| `pdf_page_renderer_io.dart` | `RenderedPdfPage`, `PdfPageRenderer` | Rasteriza hasta 50 páginas con límites y limpieza | Activo |
| `pdf_page_renderer_stub.dart` | Mismos tipos | Declara la ausencia en web | Activo · defensa |

## `lib/state/`

| Archivo | Símbolos | Métodos públicos | Estado |
|---|---|---|---|
| `scan_store.dart` | `ScanStore` | `initialize`, `retryMigration`, `importPreview`, `addAll`, `update`, `toggleFavorite`, `pruneOlderThan`, `remove`, `clear` | Activo |
| `inventory_store.dart` | `InventoryStore` | `initialize`, `importSession`, `createSession`, `activate`, `reopenSession`, `updateItemNotes`, `addScan`, `setQuantity`, `closeActive`, `deleteSession` | Activo |
| `settings_store.dart` | `SettingsStore` | `initialize`, `update` | Activo |

## `lib/features/`

| Archivo | Widget principal | Responsabilidad | Estado |
|---|---|---|---|
| `scanner/scanner_screen.dart` | `ScannerScreen` | Cámara, cinco estados, lotes cancelables, filtro de repetición | Activo |
| `scanner/domain/scanner_engine.dart` | `ScannerEngine` | Frontera estable de captura | Activo |
| `scanner/data/mobile_scanner_engine.dart` | `MobileScannerEngine` | Configuración real del controlador y de la resolución | Activo |
| `scanner/widgets/scan_status_bar.dart` | `ScanPhase`, `ScanStatusBar` | Estado siempre visible y anunciado | Activo |
| `scanner/widgets/scanner_overlay.dart` | `ScannerOverlay` | Atenúa fuera del marco y barre la línea | Activo |
| `scanner/widgets/scanner_viewport_geometry.dart` | `ScannerViewportGeometry` | Geometría del marco sin solapes | Activo |
| `result/scan_result_sheet.dart` | `ScanResultsSheet`, `ScanRecordCard` | Hechos, hipótesis, límites, acciones y evidencia | Activo |
| `history/history_screen.dart` | `HistoryScreen` | Búsqueda, filtros, notas, importación y exportación | Activo |
| `inventory/inventory_screen.dart` | `InventoryScreen` | Sesiones y conteo continuo | Activo |
| `generator/generator_screen.dart` | `GeneratorScreen` | Nueve tipos de carga, diez formatos; descarga PNG/SVG en web y hoja nativa en móvil | Activo |
| `settings/settings_screen.dart` | `SettingsScreen` | Apariencia, inspección, privacidad, datos y versión | Activo |
| `recovery/recovery_screen.dart` | `RecoveryScreen` | Registros aislados y diagnóstico | Activo |
| `formats/formats_screen.dart` | `FormatsScreen` | Catálogo informativo de simbologías | Activo |
| `formats/domain/content_parser.dart` | `ContentParser` | Interfaz de extensión | Activo |
| `formats/domain/content_parser_registry.dart` | `ContentParserRegistry`, `LegacyContentParser` | Registro ordenado con respaldo integrado | Activo |

## `tool/` — 13 herramientas

| Archivo | Qué hace | Lo usa |
|---|---|---|
| `bootstrap.py` | Genera y parchea `android/`, `ios/`, `web/` | Desarrollo y los tres workflows |
| `bootstrap.sh` · `bootstrap.ps1` | Envoltorios por sistema | Desarrollo |
| `validate_structure.py` | 14 comprobaciones offline del repositorio | CI y desarrollo |
| `verify_rootcause_contract.py` | Coherencia de las 26 reglas y del contrato de evidencia | CI y desarrollo |
| `generate_sbom.py` | SBOM CycloneDX | CI |
| `generate_license_inventory.py` | Inventario de licencias | CI |
| `generate_checksums.py` | SHA-256 de archivos | CI de release |
| `generate_source_manifest.py` | Regenera `SOURCE_MANIFEST.json` | Antes de etiquetar |
| `generate_launcher_icons.py` | Dibuja los iconos por código | Manual, requiere Pillow |
| `generate_scan_beep.py` | Genera el tono de confirmación | Manual |
| `run_quality_gate.sh` | Gate de trabajo diario | Desarrollo |
| `finalize_stable.sh` | Gate previo a etiquetar | Antes de un release |
| `build_system_documentation_pdf.py` | Genera los PDF de esta documentación | Manual |

## `test/` — 24 archivos, 88 casos

| Archivo | Casos | Qué protege |
|---|---|---|
| `core/qr_investigation_engine_test.dart` | 13 | Las reglas, las hipótesis y la decisión |
| `core/qr_evidence_exporter_test.dart` | 4 | Redacción, alteración y canonicalización |
| `core/payload_cipher_test.dart` | 5 | Sobres, llave ausente, manipulación, versión futura |
| `core/data_maintenance_test.dart` | 3 | Rotación transaccional y limpieza de llave huérfana |
| `core/schema_migrator_test.dart` | 1 | Idempotencia de las migraciones |
| `core/recovery_service_test.dart` | 1 | El paquete no filtra llave ni texto claro |
| `core/diagnostics_test.dart` | 1 | El diagnóstico no incluye mensajes ni valores |
| `core/localization_test.dart` | 4 | La interfaz solo se ofrece en español |
| `core/accessibility_test.dart` | 1 | Contraste y objetivos táctiles con texto al 200 % |
| `core/handheld_frame_test.dart` | 4 | Marco de teléfono y etiquetas de navegación |
| `core/async_write_queue_test.dart` | 2 | Orden y aislamiento de fallos |
| `core/cancellation_token_test.dart` | 2 | Cancelación y fracción de progreso |
| `features/scan_status_bar_test.dart` | 7 | Los estados visibles, incluido `Código leído` |
| `features/scanner_viewport_geometry_test.dart` | 3 | El marco no se solapa con los controles |
| `features/scanner_engine_config_test.dart` | 3 | Resolución y modo de detección de la cámara |
| `services/import_service_test.dart` | 5 | Entrada no confiable y límites |
| `services/history_repository_test.dart` | 1 | `replaceAll` atómico |
| `services/content_parser_registry_test.dart` | 1 | Aislamiento y protección del parser integrado |
| `services/scan_feedback_test.dart` | 6 | Tono, vibración, precalentado y degradación |
| `content_interpreter_test.dart` | 6 | Wi-Fi, vCard, GS1, EMVCo, `www.`, ISBN |
| `scan_security_analyzer_test.dart` | 9 | El adaptador y sus niveles de riesgo |
| `scan_record_test.dart` | 4 | Serialización, binario y contenido sensible |
| `inventory_session_test.dart` | 1 | Unidades y serialización |
| `integration_test/app_launch_test.dart` | 1 | Arranque normal o seguro; **requiere dispositivo** |

## Elementos sin uso, duplicados o de compatibilidad

Hallazgos de este recorrido, con su clasificación. El detalle y la
recomendación están en [15-risks-and-technical-debt.md](15-risks-and-technical-debt.md).

| Elemento | Clasificación | Nota |
|---|---|---|
| `RiskLevel` y `SecurityAssessment` | **Legado declarado** | El propio código lo documenta: existe para filtros e importaciones heredadas; su verdad es `QrInvestigation.severity` |
| `FeatureFlags` (9 banderas) | **Experimental apagado** | Se serializa en preferencias pero ninguna bandera se lee en `lib/` |
| Claves inglesas de `AppLocalizations` | Parcial | Existen y hay una prueba que impide exponer inglés hasta traducir todas las pantallas |
| `PayloadCipher.legacyKeyId` | Duplicado aparente | Vale `'v2'`, igual que `currentKeyId` |
| `AppLanguage.en` | Inalcanzable por la interfaz | El desplegable de Ajustes lo convierte a «Sistema» |
| `ScannerEngine.controller` | Fuga de abstracción | La frontera expone el tipo del paquete que pretende ocultar |
| `HandheldFrame` en móvil | Sin efecto | Por debajo de 560 px no envuelve nada; es intencional |
