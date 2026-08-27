# 05 · Referencia técnica

Catálogo de consulta. Todos los nombres son literales del código y pueden
buscarse con `grep`.

## Constantes de identidad y versión

| Constante | Archivo | Valor | Nota |
|---|---|---|---|
| `appVersion` | `lib/core/app_info.dart` | `'0.1.1'` | Único lugar donde se escribe la versión visible. `tool/validate_structure.py` falla si diverge de `pubspec.yaml` |
| `appName` | `lib/core/app_info.dart` | `'RootCause QR Inspector'` | Verificado por `tool/verify_rootcause_contract.py` |
| `QrInvestigationEngine.engineVersion` | motor | `'0.1.0'` | Versión **del motor de reglas**, independiente de la app. Solo sube si cambia una regla |
| `QrInvestigation.schema` | contrato | `'rootcause.qr-investigation.v1'` | |
| `QrEvidenceExporter.schema` | exportador | `'rootcause.evidence.qr.v1'` | |

## Límites y umbrales

| Constante | Archivo | Valor | Efecto al superarlo |
|---|---|---|---|
| `HistoryRepository.maxItems` | historial | `5000` | Se borran los registros más antiguos |
| `ImportService.maxHistoryRecords` | importación | `5000` | `FormatException` antes de tocar la base |
| `ImportService.maxImportBytes` | importación | `25 * 1024 * 1024` | `FormatException` |
| `ImportService.maxJsonDepth` | importación | `32` | `FormatException` |
| `ImportService.maxJsonNodes` | importación | `100000` | `FormatException` |
| `ImportService.maxInventoryItems` | importación | `10000` | `FormatException` |
| `ImportService.currentSchemaVersion` | importación | `2` | Un respaldo con versión mayor se rechaza |
| `AppDiagnostics.maxEntries` | diagnóstico | `100` | Se descartan las entradas más antiguas |
| `SchemaMigrator.currentVersion` | migrador | `4` | |
| `PayloadCipher.currentVersion` | cifrado | `2` | Un sobre con versión mayor se rechaza |
| `HandheldFrame.maxWidth` | `app.dart` | `560` | Por encima, la interfaz se centra a ese ancho |
| `_repeatWindow` | `scanner_screen.dart` | `2500 ms` | Ventana de repetición del mismo código |
| `MobileScannerEngine.inspectionResolution` | motor de captura | `Size(1920, 1080)` | Resolución pedida en inspección |
| `MobileScannerEngine.inventoryResolution` | motor de captura | `Size(1280, 720)` | Resolución pedida en inventario |
| `maxPages` de `PdfPageRenderer.pickAndRender` | PDF | `50` | Se ignoran las páginas siguientes |
| `limit` de `pickMultiImage` | escáner | `20` | Máximo de imágenes por lote |

## Valores por defecto de `QrAnalysisPolicy`

| Campo | Valor | Regla que lo consume |
|---|---|---|
| `maxUrlLength` | `240` | `url-excessive-length` |
| `maxDomainLabels` | `5` | `host-deep-subdomains` |
| `allowPrivateTargets` | `false` | `host-private-or-local` |
| `trustedBrands` | `[]` | `brand-domain-mismatch` |

## Tipos de datos

### Enumeraciones

| Enum | Archivo | Valores |
|---|---|---|
| `QrSeverity` | investigación | `normal`, `warning`, `critical` |
| `QrFindingConfidence` | investigación | `low`, `medium`, `high` |
| `QrFindingCategory` | investigación | `transport`, `identity`, `obfuscation`, `destination`, `credential`, `download`, `redirect`, `sensitiveAction` |
| `QrActionDecision` | investigación | `allow`, `confirm`, `inspectOnly`, `block` |
| `ContentKind` | `parsed_content.dart` | `url`, `wifi`, `contact`, `event`, `email`, `phone`, `sms`, `geo`, `otp`, `gs1`, `isbn`, `product`, `payment`, `crypto`, `identity`, `binary`, `text` |
| `RiskLevel` | analizador | `low`, `caution`, `high` — legado |
| `AppLanguage` | ajustes | `system`, `esCl`, `es`, `en` — `en` no se ofrece |
| `ImportStrategy` | importación | `merge`, `skipDuplicates`, `replace` |
| `RecoveryEntityType` | recuperación | `history`, `inventory`, `migration`, `database`, `startup` |
| `RecoveryIssueState` | recuperación | `unresolved`, `recovered`, `deleted` |
| `ScanPhase` | barra de estado | `starting`, `scanning`, `captured`, `paused`, `unavailable` |

### Estructuras principales

| Clase | Campos |
|---|---|
| `QrEvidenceFact` | `id`, `value` |
| `QrFinding` | `id`, `severity`, `score`, `confidence`, `category`, `evidence[]` |
| `QrInvestigation` | `engineVersion`, `analyzedAt`, `payloadSha256`, `severity`, `score`, `action`, `normalizedHost?`, `effectiveUri?`, `findings[]`, `hypotheses[]`, `evaluatedRuleIds[]`, `limitations[]` |
| `ParsedContent` | `kind`, `title`, `summary?`, `fields`, `sensitive` |
| `ScanRecord` | `id`, `rawValue`, `displayValue`, `format`, `contentType`, `scannedAt`, `source`, `riskLevel`, `riskReasons[]`, `canOpen`, `parsed`, `investigation`, `favorite`, `tags[]`, `notes` |
| `InventoryItem` | `code`, `format`, `label`, `quantity`, `firstScannedAt`, `lastScannedAt`, `notes` |
| `InventorySession` | `id`, `name`, `createdAt`, `closedAt?`, `items` |
| `RecoveryIssue` | `id`, `entityType`, `entityId`, `detectedAt`, `code`, `state`, `encryptedPayload?` |
| `CipherEnvelopeInfo` | `version`, `algorithm`, `keyId`, `legacy` |
| `HistoryMigrationStatus` | `completed`, `migrated`, `errorCode?`, `backupPresent` |
| `EncryptionRotationResult` | `keyId`, `historyRecords`, `inventorySessions` |
| `SchemaMigrationResult` | `fromVersion`, `toVersion`, `applied[]` |
| `ScannerViewportGeometry` | `compact`, `statusReserve`, `controlsReserve`, `scanWindow` |
| `RenderedPdfPage` | `pageNumber`, `imagePath` |
| `DiagnosticEntry` | `at`, `area`, `errorType`, `stackFingerprint` |

## Funciones y métodos principales

### `QrInvestigationEngine.analyze`

| Aspecto | Detalle |
|---|---|
| Archivo | `lib/core/investigation/qr_investigation_engine.dart` |
| Firma | `static QrInvestigation analyze(String rawValue, {ParsedContent? parsed, QrAnalysisPolicy policy = const QrAnalysisPolicy(), DateTime? analyzedAt})` |
| Propósito | Producir hechos, hipótesis, decisión y límites a partir de una carga |
| Retorna | `QrInvestigation` serializable |
| Excepciones | Ninguna: toda entrada produce un resultado |
| Efectos secundarios | Ninguno. Función pura |
| Invocada por | `ScanSecurityAnalyzer.analyze` y, a través de él, las tres fábricas de `ScanRecord` |
| Invoca | `_declaredScheme`, `_toWebUri`, `_rawAuthority`, `_isIpAddress`, `_isPrivateOrLocalHost`, `_hasMixedScripts`, `_containsControlOrInvisible`, `_safeDecode`, `_looksLikeCredentialLure`, `_nestedRedirect`, `_sameHostFamily`, `_brandMismatch`, `_comparable`, `_hostMatches` |
| Ejemplo | `analyze('https://xn--pple-43d.example/login')` → `severity: critical`, hallazgos `host-punycode` y `credential-lure-path`, hipótesis `qr-phishing-suspected` y `credential-theft-suspected` |
| Riesgo al modificar | Cambiar condición o peso sin subir `engineVersion` rompe la comparabilidad de las evidencias ya exportadas. `verify_rootcause_contract.py` falla si el número de reglas deja de ser 26 o si un id no existe en esquema, textos y heurísticas |

### `QrEvidenceExporter.toMap`

| Aspecto | Detalle |
|---|---|
| Firma | `static Map<String, Object?> toMap(ScanRecord record, {bool includeRawPayload = false, String? previousEvidenceHash})` |
| Propósito | Paquete forense portable |
| Excepciones | `ArgumentError` si `previousEvidenceHash` no es SHA-256 hexadecimal en minúsculas |
| Efectos secundarios | Ninguno |
| Riesgo al modificar | Con `includeRawPayload` en `false` **debe** eliminar `effectiveUri`; sin eso una consulta con token reaparece por una ruta secundaria |

### `QrEvidenceExporter.verify`

| Aspecto | Detalle |
|---|---|
| Firma | `static bool verify(Map<String, dynamic> bundle)` |
| Retorna | `true` si `bundleHash` coincide con el recalculado sobre el JSON canónico |
| Nota | Es un checksum sin clave. No prueba autoría; el campo `assurance` lo declara |

### `PayloadCipher`

| Método | Firma | Excepciones |
|---|---|---|
| `encryptJson` | `Future<String> encryptJson(Map<String, dynamic> value, {String? keyId})` | `StateError('encryption_key_missing:<id>')` si la llave ya se marcó ausente |
| `decryptJson` | `Future<Map<String, dynamic>> decryptJson(String encoded)` | `FormatException` por versión o algoritmo; `StateError` por llave ausente; error de MAC si la carga fue manipulada |
| `inspect` | `CipherEnvelopeInfo inspect(String encoded)` | `FormatException` si no es JSON |
| `upgradeEnvelope` | `Future<String> upgradeEnvelope(String encoded)` | Las de descifrado |
| `activateKey` | `void activateKey(String keyId)` | `ArgumentError` si el id está vacío |

### `ScanRecord.fromJson`

| Aspecto | Detalle |
|---|---|
| Firma | `factory ScanRecord.fromJson(Map<String, dynamic> json, {bool trustDerivedAnalysis = true})` |
| Riesgo al modificar | Con `true` acepta el análisis del archivo; la importación **debe** pasar `false`. `verify_rootcause_contract.py` comprueba que `import_service.dart` contiene `trustDerivedAnalysis: false` |

### `ImportService.parseHistoryBytes`

| Aspecto | Detalle |
|---|---|
| Firma | `static HistoryImportPreview parseHistoryBytes(List<int> bytes, {required Set<String> existingIds, String fileName = 'respaldo.json'})` |
| Excepciones | `FormatException` por tamaño, forma, aplicación incompatible, tipo, versión futura o exceso de registros |
| Efectos secundarios | **Ninguno**: no toca la base. La escritura ocurre después, en `ScanStore.importPreview` |

### `DataMaintenanceService.rotateEncryptionKey`

| Aspecto | Detalle |
|---|---|
| Firma | `Future<EncryptionRotationResult> rotateEncryptionKey()` |
| Excepciones | `StateError('encryption_rotation_in_progress')`, `history_payload_missing:<id>`, `inventory_payload_missing:<id>` |
| Efectos secundarios | Reescribe historial e inventario y cambia la llave activa, todo en una transacción |
| Riesgo al modificar | Mover el cifrado dentro de la transacción alarga el bloqueo y reabre la posibilidad de un estado mixto |

### Otras funciones de consulta frecuente

| Función | Archivo | Qué devuelve |
|---|---|---|
| `ScanRecord.payloadForBarcode` | modelo | Texto del código o `binary-base64:<...>`; cadena vacía si no hay nada |
| `ContentInterpreter.parse` | servicio | `ParsedContent`, incluida la marca `sensitive` |
| `ScanSecurityAnalyzer.normalizedActionUri` | núcleo | `Uri` accionable o `null` |
| `ScannerViewportGeometry.forSize` | escáner | Geometría del marco sin solapes |
| `navigationLabelBehaviorForWidth` | `app.dart` | Oculta las etiquetas por debajo de 360 dp |
| `AsyncWriteQueue.run<T>` | rendimiento | Encola una operación y devuelve su valor o su error |
| `installGlobalErrorHandlers` | diagnóstico | Nada; instala los capturadores globales |

## Los 26 identificadores de regla

`transport-http`, `authority-userinfo`, `host-punycode`, `host-mixed-script`,
`host-unicode`, `host-ip-literal`, `host-private-or-local`, `host-shortener`,
`host-deep-subdomains`, `host-trailing-dot`, `host-hyphen-density`,
`host-empty`, `port-unusual`, `url-excessive-length`, `url-control-character`,
`authority-obfuscated`, `encoded-separator`, `download-dangerous-extension`,
`credential-lure-path`, `tracking-excessive`, `redirect-nested-domain`,
`brand-domain-mismatch`, `scheme-blocked`, `sensitive-secret`,
`payment-instruction`, `opaque-binary-payload`.

Condición, severidad, peso, confianza y falso positivo de cada una:
[`../rootcause/HEURISTICS.md`](../rootcause/HEURISTICS.md).

## Las 6 hipótesis

`qr-phishing-suspected`, `credential-theft-suspected`,
`malware-delivery-suspected`, `payment-substitution-review`,
`local-network-lure`, `unsafe-uri-execution`.

## Los 7 límites declarados

`no-remote-reputation`, `no-dns-resolution`, `no-certificate-validation`,
`no-redirect-following`, `no-domain-age-check`,
`no-visual-sticker-tamper-detection`, `no-destination-safety-guarantee`.

## Identificadores de evidencia

`scheme`, `host`, `normalizedHost`, `port`, `extension`, `subdomainLabels`,
`length`, `redirectHost`, `redirectParameter`, `brandId`, `token`,
`trackingParameters`, `contentKind`.

## Claves de preferencias

| Clave | Tipo | Por defecto | Se restablece con `resetNonSensitive` |
|---|---|---|---|
| `theme_mode` | String | `system` | Sí |
| `language` | String | `system` | Sí |
| `sound_enabled` | bool | `true` | Sí |
| `vibration_enabled` | bool | `true` | Sí |
| `save_history` | bool | `true` | **No** |
| `private_mode` | bool | `false` | **No** |
| `auto_torch` | bool | `false` | Sí |
| `use_scan_window` | bool | `true` | Sí |
| `confirm_before_open` | bool | `true` | Sí |
| `hide_sensitive_values` | bool | `true` | Sí |
| `biometric_lock` | bool | `false` | **No** |
| `high_contrast` | bool | `false` | Sí |
| `large_controls` | bool | `false` | Sí |
| `reduce_motion` | bool | `false` | Sí |
| `clear_clipboard_seconds` | int | `30` | Sí |
| `history_retention_days` | int | `0` (sin límite) | Sí |
| `feature_flags` | String JSON | todas `false` | Sí |
| `scan_history_v1` | String | — | Origen heredado que se migra y se borra |
| `scan_history_v1_backup` | String | — | Respaldo cifrado del origen heredado |
| `history_migrated_to_v2` | bool | — | Marca de migración completada |
| `history_migration_error` | String | — | Código del último fallo de migración |
| `encryption_active_key_id` | String | — | Se traslada a la base y se borra de preferencias |

## Almacenes de la base de datos

| Almacén | Clave | Contenido |
|---|---|---|
| `scan_history` | id del registro | `id`, `scannedAt`, `payload` cifrado |
| `inventory_sessions` | id de sesión | `id`, `createdAt`, `payload` cifrado |
| `recovery_issues` | id determinista | Incidencia serializada con su sobre |
| `_schema_meta` | nombre del metadato | Versión de esquema y marcas |
| `_security_meta` | `encryption_active_key_id` | Identificador de la llave activa |

## Rutas de navegación

**No hay rutas con nombre ni router declarativo.** La navegación es:

| Destino | Cómo se llega |
|---|---|
| Cinco secciones principales | Índice del `NavigationBar` en `HomeShell` |
| Hoja de resultado | `showModalBottomSheet` desde el escáner o el historial |
| `FormatsScreen` | `MaterialPageRoute` desde Ajustes |
| `RecoveryScreen` | `MaterialPageRoute` desde Ajustes |
| Diálogos | `showDialog` en el punto de uso |

## Endpoints

**No identificados.** El sistema no expone ni consume ningún endpoint HTTP. Ver
[09-apis-and-integrations.md](09-apis-and-integrations.md).

## Comandos

| Comando | Efecto |
|---|---|
| `flutter pub get` | Resuelve dependencias |
| `python tool/bootstrap.py --platforms android,web` | Genera y parchea las carpetas nativas |
| `python tool/validate_structure.py --require-lock` | 14 comprobaciones offline |
| `python tool/verify_rootcause_contract.py` | Coherencia del contrato de reglas |
| `flutter analyze --fatal-infos` | Análisis estático estricto |
| `flutter test` | 87 casos |
| `flutter build apk --release` | APK instalable |
| `python tool/generate_source_manifest.py` | Regenera los hashes de la fuente |
| `python tool/build_system_documentation_pdf.py` | Genera los PDF de esta documentación |

## Archivos de configuración

| Archivo | Formato | Qué configura |
|---|---|---|
| `pubspec.yaml` | YAML | Dependencias, versión, assets |
| `analysis_options.yaml` | YAML | Lints |
| `.fvmrc` | JSON | Versión de Flutter |
| `.gitattributes` | texto | Finales de línea LF |
| `config/rootcause-qr-policy.example.json` | JSON | Ejemplo de política, no se carga en tiempo de ejecución |
| `.github/workflows/*.yml` | YAML | CI, release y publicación de la landing |
| `.github/dependabot.yml` | YAML | Actualizaciones, con `pdfrx` bloqueado por encima de 2.4.5 |

## Códigos de error

Estos códigos aparecen en las incidencias de recuperación, en las excepciones y
en las preferencias. Son cadenas estables, aptas para diagnóstico.

| Código | Origen | Significado |
|---|---|---|
| `missing_payload` | repositorios | El registro no tiene sobre cifrado |
| `decrypt_<Tipo>` | repositorios | El descifrado falló; `<Tipo>` es la clase de la excepción |
| `legacy_<Tipo>` | migración de historial | La conversión del historial heredado falló |
| `encryption_key_missing:<keyId>` | `PayloadCipher` | La llave de ese sobre no está en el almacén |
| `encryption_rotation_in_progress` | mantenimiento | Ya hay una rotación en curso |
| `history_payload_missing:<id>` | rotación | Un registro de historial está incompleto |
| `inventory_payload_missing:<id>` | rotación | Una sesión está incompleta |
| `migration_limit_exceeded` | migración | El resultado superaría los 5000 registros |
| `migration_verification_failed` | migración | La transacción no contiene todo lo esperado |
| `history_v1_to_v2` | recuperación | Identificador de la incidencia de migración |
| `legacy_not_list` | migración | El historial heredado no era una lista |

Los `FormatException` de importación llevan mensaje en español legible por la
persona y se muestran como «El respaldo no es válido o no pudo leerse».

### Códigos de la cámara

| Código de `MobileScannerErrorCode` | Mensaje mostrado |
|---|---|
| `permissionDenied` | «Falta el permiso de cámara. Actívalo en los ajustes del sistema y vuelve a intentarlo.» |
| `unsupported` | «Este dispositivo no permite leer códigos con la cámara.» |
| cualquier otro | «La cámara no pudo iniciarse. Toca «Reintentar».» |
