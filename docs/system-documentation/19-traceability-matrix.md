# 19 · Matriz de trazabilidad

Permite seguir una funcionalidad desde la interfaz hasta el dato y su prueba.

**Estado de validación:**
🟢 cubierto por prueba automática · 🟡 parcial · 🔴 sin prueba ·
📱 requiere dispositivo

## Funcionalidades principales

| # | Funcionalidad | Regla de negocio | Interfaz | Módulo | Clase / función | Persistencia | Prueba | Documento | Estado |
|---|---|---|---|---|---|---|---|---|---|
| F-01 | Leer un código con la cámara | Ninguna carga se ejecuta al detectarla | `ScannerScreen` | `features/scanner` | `_handleCapture` | — | — | [06](06-deep-code-explanation.md) | 📱 |
| F-02 | La lectura cubre toda la imagen | El marco es guía, no filtro | `ScannerScreen` | `features/scanner` | `MobileScanner` sin `scanWindow` | — | `scanner_engine_config_test` (config) | [`SCANNER_UX`](../quality/SCANNER_UX.md) | 🟡 📱 |
| F-03 | Alcanzar un código lejano | Declarar la resolución en vez de aceptar 640×480 | — | `features/scanner/data` | `inspectionResolution` | — | `scanner_engine_config_test` | [`SCANNER_UX`](../quality/SCANNER_UX.md) | 🟡 📱 |
| F-04 | Confirmar una captura | Una lectura conseguida no se anuncia como pausa | `ScanStatusBar` | `features/scanner/widgets` | `ScanPhase.captured` | — | `scan_status_bar_test` | [`SCANNER_UX`](../quality/SCANNER_UX.md) | 🟢 |
| F-05 | Tono y vibración | Nunca pueden romper una lectura | — | `services` | `ScanFeedback.success` | — | `scan_feedback_test` (6) | [06](06-deep-code-explanation.md) | 🟢 |
| F-06 | Releer el mismo código | La repetición se explica, no se silencia | `ScannerScreen` | `features/scanner` | `_repeatWindow`, `_showRepeatNotice` | — | 🔴 | [`SCANNER_UX`](../quality/SCANNER_UX.md) | 🔴 |
| F-07 | Interpretar el contenido | 17 familias reconocidas | `ScanRecordCard` | `services` | `ContentInterpreter.parse` | `parsed` | `content_interpreter_test` (6 de 17) | [06](06-deep-code-explanation.md) | 🟡 |
| F-08 | Analizar con 26 reglas | Hechos, nunca veredictos | `_RiskBanner` | `core/investigation` | `QrInvestigationEngine.analyze` | `investigation` | `qr_investigation_engine_test` (13) | [`HEURISTICS`](../rootcause/HEURISTICS.md) | 🟢 |
| F-09 | Separar hipótesis de hechos | Las hipótesis no suman puntos | `_RiskBanner` | `core/investigation` | Bloque de hipótesis | `hypotheses` | `qr_investigation_engine_test` | [`HEURISTICS`](../rootcause/HEURISTICS.md) | 🟢 |
| F-10 | Decidir la acción | `block` retira el botón; `confirm` exige diálogo | `ScanRecordCard` | `core/investigation` | `QrActionDecision` | `verdict.action` | 🔴 en la interfaz; `verify_rootcause_contract` la comprueba por texto | [03](03-architecture.md) | 🟡 |
| F-11 | Declarar los límites | Un dato ausente nunca es favorable | `_RiskBanner` | `core/investigation` | `limitations` | `limitations` | `qr_investigation_engine_test` | [`LIMITATIONS`](../rootcause/LIMITATIONS.md) | 🟢 |
| F-12 | Frase de resultado normal | No se puede eliminar | `_RiskBanner` | `features/result` | Literal en la interfaz | — | `verify_rootcause_contract` | [`LIMITATIONS`](../rootcause/LIMITATIONS.md) | 🟢 |
| F-13 | Exportar evidencia redactada | Sin carga ni URL efectiva | Botón «Evidencia» | `core/investigation` | `QrEvidenceExporter.toMap` | Archivo | `qr_evidence_exporter_test` (4) | [09](09-apis-and-integrations.md) | 🟢 |
| F-14 | Verificar una evidencia | Checksum canónico, no firma | — | `core/investigation` | `verify`, `_canonicalJson` | — | `qr_evidence_exporter_test` | [09](09-apis-and-integrations.md) | 🟢 |
| F-15 | No persistir lo sensible | OTP, Wi-Fi, pago e identidad fuera del historial | — | `features/scanner` | `_persistAndShow` | `scan_history` | 🔴 en la pantalla; `scan_record_test` cubre la clasificación | [08](08-data-flow.md) | 🟡 |
| F-16 | Cifrar lo persistido | AES-256-GCM por registro | — | `core/security` | `PayloadCipher.encryptJson` | `payload` | `payload_cipher_test` (5) | [11](11-security.md) | 🟢 |
| F-17 | No recrear una llave ausente | Evita pérdida irreversible | Centro de recuperación | `core/security` | `decryptJson` con `read` | — | `payload_cipher_test` | [11](11-security.md) | 🟢 |
| F-18 | Aislar un registro ilegible | Nunca se borra solo | Centro de recuperación | `services` + `core/recovery` | `HistoryRepository.load` | `recovery_issues` | 🔴 | [`RECOVERY`](../quality/RECOVERY.md) | 🔴 |
| F-19 | Recuperar o descartar | Solo el registro afectado | `RecoveryScreen` | `core/recovery` | `retry`, `discard` | Ambos almacenes | 🔴 (solo `exportBundle`) | [`RECOVERY`](../quality/RECOVERY.md) | 🔴 |
| F-20 | Paquete de recuperación sin llave | El texto cifrado se conserva | `RecoveryScreen` | `core/recovery` | `exportBundle` | Archivo | `recovery_service_test` | [11](11-security.md) | 🟢 |
| F-21 | Rotar la llave | Todo o nada, sin llave huérfana | `SettingsScreen` | `core/security` | `rotateEncryptionKey` | Ambos + `_security_meta` | `data_maintenance_test` (3) | [06](06-deep-code-explanation.md) | 🟢 |
| F-22 | Migrar el esquema | Idempotente y transaccional | — | `core/database` | `SchemaMigrator.migrate` | `_schema_meta` | `schema_migrator_test` | [07](07-database.md) | 🟢 |
| F-23 | Migrar el historial heredado | Verificar antes de borrar el origen | Ajustes → reintentar | `services` | `_migrateLegacyHistory` | `scan_history` | 🔴 | [`MIGRATIONS`](../quality/MIGRATIONS.md) | 🔴 |
| F-24 | Importar sin confiar | Todo campo derivado se recalcula | `HistoryScreen` | `services` | `parseHistoryBytes` + `trustDerivedAnalysis: false` | `scan_history` | `import_service_test` (5) | [06](06-deep-code-explanation.md) | 🟢 |
| F-25 | Vista previa de importación | Nada se escribe antes de elegir | Diálogo | `services` + `state` | `HistoryImportPreview`, `importPreview` | — | `import_service_test` | [06](06-deep-code-explanation.md) | 🟡 |
| F-26 | Exportar historial completo | Advertir que va en claro | `HistoryScreen` | `services` | `ExportService` | Archivo | 🔴 | [08](08-data-flow.md) | 🔴 |
| F-27 | Buscar y filtrar | En memoria, sobre lo descifrado | `HistoryScreen` | `features/history` | Filtro del `build` | — | 🔴 | [04](04-code-map.md) | 🔴 |
| F-28 | Notas y etiquetas | Se persisten cifradas | `HistoryScreen` | `state` | `ScanStore.update` | `payload` | 🔴 | [07](07-database.md) | 🔴 |
| F-29 | Retención del historial | 0 significa sin límite | `SettingsScreen` | `services` | `pruneOlderThan` | `scan_history` | 🔴 | [10](10-configuration.md) | 🔴 |
| F-30 | Límite de 5000 | Se eliminan los más antiguos | — | `services` | `_trim` | `scan_history` | 🔴 | [07](07-database.md) | 🔴 |
| F-31 | Contar inventario | Cada lectura suma una unidad | `InventoryScreen` | `state` | `InventoryStore.addScan` | `inventory_sessions` | `inventory_session_test` (modelo) | [04](04-code-map.md) | 🟡 📱 |
| F-32 | Contar unidades repetidas | Diez cajas iguales son diez unidades | `InventoryScreen` | `features/inventory` | `_onDetect` con `DetectionSpeed.normal` | `inventory_sessions` | 🔴 | [`SCANNER_UX`](../quality/SCANNER_UX.md) | 🔴 📱 |
| F-33 | Serializar escrituras | Sin carreras entre cámara y edición | — | `core/performance` | `AsyncWriteQueue.run` | — | `async_write_queue_test` (2) | [06](06-deep-code-explanation.md) | 🟢 |
| F-34 | Cerrar y reabrir sesión | Cerrada no acepta lecturas | `InventoryScreen` | `state` | `closeActive`, `reopenSession` | `inventory_sessions` | 🔴 | [04](04-code-map.md) | 🔴 |
| F-35 | Generar códigos | Sin enviar datos a un servidor | `GeneratorScreen` | `features/generator` | `_payload`, `_barcode` | — | 🔴 | [04](04-code-map.md) | 🔴 |
| F-36 | Leer imágenes por lotes | Máximo 20, cancelable | `ScannerScreen` | `features/scanner` | `_scanFromGallery` | — | 🔴 | [`PERFORMANCE`](../quality/PERFORMANCE.md) | 🔴 📱 |
| F-37 | Leer páginas de PDF | Máximo 50, con limpieza | `ScannerScreen` | `services` | `PdfPageRenderer.pickAndRender` | Temporal | 🔴 | [`PERFORMANCE`](../quality/PERFORMANCE.md) | 🔴 📱 |
| F-38 | Cancelar un lote | Sin modificar el historial | Diálogo | `core/performance` | `CancellationToken` | — | `cancellation_token_test` (2) | [06](06-deep-code-explanation.md) | 🟢 |
| F-39 | Bloqueo de la aplicación | Se rebloquea al perder el primer plano | `BiometricLockGate` | `app.dart` | `didChangeAppLifecycleState` | — | 🔴 | [11](11-security.md) | 🔴 📱 |
| F-40 | Arranque seguro | Cuatro salidas ante un fallo | `_StartupRecovery` | `bootstrap_host.dart` | `StartupFailure.from` | — | `app_launch_test` | [06](06-deep-code-explanation.md) | 🟡 📱 |
| F-41 | Modo temporal | Nada sobrevive al cierre | Banner | `bootstrap.dart` | `openTemporary` + llave en memoria | Memoria | Usado en varias pruebas | [06](06-deep-code-explanation.md) | 🟡 |
| F-42 | Diagnóstico privado | Sin mensajes ni cargas | `RecoveryScreen` | `core/diagnostics` | `AppDiagnostics.exportJson` | Memoria | `diagnostics_test` | [11](11-security.md) | 🟢 |
| F-43 | Copiar con borrado | Confirmación si es sensible | `ScanRecordCard` | `services` | `ClipboardService.copy` | Portapapeles | 🔴 | [11](11-security.md) | 🔴 |
| F-44 | Ocultar valores sensibles | Puntos en vez del valor | `ScanRecordCard` | `features/result` | `conceal` | — | 🔴 | [11](11-security.md) | 🔴 |
| F-45 | Accesibilidad | Contraste, tamaño táctil, movimiento | `SettingsScreen` | `core/theme` | `AppTheme` | Preferencias | `accessibility_test`, `scan_status_bar_test` | [`ACCESSIBILITY`](../quality/ACCESSIBILITY.md) | 🟡 |
| F-46 | Solo español | Ninguna interfaz a medio traducir | — | `core/localization` | Delegado que rechaza `en` | Preferencias | `localization_test` (4) | [`ACCESSIBILITY`](../quality/ACCESSIBILITY.md) | 🟢 |
| F-47 | Marco de teléfono | No estirar en pantallas grandes | `HandheldFrame` | `app.dart` | `maxWidth = 560` | — | `handheld_frame_test` (4) | [03](03-architecture.md) | 🟢 |
| F-48 | Marco sin solapes | Nunca bajo los controles | `ScannerOverlay` | `features/scanner/widgets` | `ScannerViewportGeometry.forSize` | — | `scanner_viewport_geometry_test` (3) | [04](04-code-map.md) | 🟢 |
| F-49 | Política de marcas | Token fuera de dominio autorizado | **Sin interfaz** | `core/investigation` | `QrAnalysisPolicy` | — | `qr_investigation_engine_test` | [10](10-configuration.md) | 🟡 |
| F-50 | Extender el intérprete | Sin tocar el parser integrado | — | `features/formats/domain` | `ContentParserRegistry` | — | `content_parser_registry_test` | [09](09-apis-and-integrations.md) | 🟢 |

## Reglas de negocio no negociables

Las que rompen el producto si desaparecen.

| Id | Regla | Dónde se aplica | Quién la protege | Estado |
|---|---|---|---|---|
| RN-01 | Ninguna carga se ejecuta al detectarla | Toda la aplicación | Revisión humana | 🟡 |
| RN-02 | Un resultado normal no afirma que el destino sea seguro | `_RiskBanner` | `verify_rootcause_contract` | 🟢 |
| RN-03 | Hallazgo e hipótesis son campos distintos | Contrato y esquema | Esquema + pruebas | 🟢 |
| RN-04 | Las hipótesis no suman puntos | Motor | `qr_investigation_engine_test` | 🟢 |
| RN-05 | La severidad es el máximo, no el puntaje | Motor | Íd. | 🟢 |
| RN-06 | `block` retira la acción externa | `ScanRecordCard` | `verify_rootcause_contract` (por texto) | 🟡 |
| RN-07 | `confirm` exige diálogo aunque la confirmación general esté apagada | Íd. | Íd. | 🟡 |
| RN-08 | La evidencia omite carga, parseo y `effectiveUri` | Exportador | `qr_evidence_exporter_test` + verificador | 🟢 |
| RN-09 | El checksum nunca se describe como firma | Exportador y documentación | `assurance` + verificador | 🟢 |
| RN-10 | Un respaldo no puede imponer campos derivados | Importación | `import_service_test` + verificador | 🟢 |
| RN-11 | Un registro sensible no se persiste | `_persistAndShow` | 🔴 **sin prueba** | 🔴 |
| RN-12 | Un registro ilegible se aísla, no se borra | Repositorios | 🔴 **sin prueba** | 🔴 |
| RN-13 | Una llave ausente no se recrea | `PayloadCipher` | `payload_cipher_test` | 🟢 |
| RN-14 | La migración verifica antes de borrar el origen | `HistoryRepository` | 🔴 **sin prueba** | 🔴 |
| RN-15 | La huella cubre la carga exacta | Motor | `qr_investigation_engine_test` | 🟢 |
| RN-16 | Cambiar una regla obliga a subir `engineVersion` | Proceso | Revisión humana | 🔴 |
| RN-17 | La lectura no descarta un código en silencio | `ScannerScreen` | 🔴 **sin prueba** | 🔴 |
| RN-18 | No hay telemetría | Toda la aplicación | Ausencia de dependencias de red | 🟢 |

## Resumen de cobertura

| Estado | Funcionalidades | Reglas de negocio |
|---|---|---|
| 🟢 Cubierto | 21 | 10 |
| 🟡 Parcial | 12 | 4 |
| 🔴 Sin prueba | 17 | 4 |

**Las cuatro reglas de negocio en rojo son la mayor deuda de calidad del
repositorio.** Tres de ellas —RN-11, RN-12 y RN-14— protegen datos de la persona;
la cuarta, RN-17, es la que motivó la versión 0.1.1. Ver
[15-risks-and-technical-debt.md](15-risks-and-technical-debt.md) y la propuesta
priorizada de [12-testing-and-quality.md](12-testing-and-quality.md).

## De la interfaz al dato: dos ejemplos completos

### Inspeccionar un QR y guardarlo

```text
ScannerScreen (pestaña «Escanear»)
  └─ MobileScanner.onDetect
      └─ _handleCapture                    filtro de repetición 2,5 s
          └─ ScanRecord.fromBarcode
              ├─ ContentParserRegistry.parse → ParsedContent (decide `sensitive`)
              └─ ScanSecurityAnalyzer.analyze
                  └─ QrInvestigationEngine.analyze → QrInvestigation
          ├─ _persistAndShow
          │   ├─ filtro: !isSensitive          ← RN-11
          │   └─ ScanStore.addAll
          │       └─ HistoryRepository.upsertAll
          │           └─ PayloadCipher.encryptJson    ← AES-256-GCM
          │               └─ store `scan_history`, campo `payload`
          └─ ScanResultsSheet → ScanRecordCard
              ├─ _RiskBanner        hallazgos, hipótesis, límites  ← RN-02
              └─ acciones           copiar · compartir · evidencia · abrir  ← RN-06
```

### Exportar evidencia de un caso

```text
ScanRecordCard → botón «Evidencia»
  └─ _shareEvidence
      └─ QrEvidenceExporter.toJson(record)      includeRawPayload = false
          └─ toMap
              ├─ investigation.remove('effectiveUri')   ← RN-08
              ├─ redaction = 'payload-omitted'
              ├─ _canonicalJson(content)                claves ordenadas
              └─ integrity.bundleHash = SHA-256(...)    ← RN-09
      └─ SharePlus → archivo rootcause-qr-evidence-<id>.json
```

## Trazabilidad de la corrección 0.1.1

| Síntoma reportado | Causa | Corrección | Prueba | Falta |
|---|---|---|---|---|
| Volver a apuntar al mismo código no hacía nada | `DetectionSpeed.noDuplicates` | `DetectionSpeed.normal` + filtro con aviso | `scanner_engine_config_test` | Ciclo completo en dispositivo |
| Un código legible no se leía | El marco filtraba como `scanWindow` | Detección en toda la vista previa | 🔴 | Confirmación en dispositivo |
| Un código lejano no se leía | Resolución sin declarar: 640×480 | 1920×1080 y 1280×720 | `scanner_engine_config_test` | Alcance real y consumo |
| Una captura parecía una pausa | Reutilizaba `ScanPhase.paused` | `ScanPhase.captured` | `scan_status_bar_test` | Captura de pantalla real |
| La confirmación llegaba tarde | Se esperaba el tono | `warmUp` + reproducción no bloqueante | `scan_feedback_test` | Latencia audible |
| El inventario no contaba repetidos | `noDuplicates` | Mismo cambio de detector | 🔴 | Diez unidades en dispositivo |
