# Alcance de la versión 1.0.0

> Registro histórico de Universal Code Scanner 1.0.0 conservado para
> trazabilidad del sustrato. No describe la validación de RootCause QR
> Inspector 0.1.1; consultar [`../../VALIDATION.md`](../../VALIDATION.md).

Matriz de lo que la primera versión pública incorpora, cómo se verificó y qué
queda fuera de este entorno. La columna «verificación» distingue lo comprobado
con el toolchain real de lo que depende de hardware o de la CI.

| Área | Incorporado en la fuente | Verificación |
|---|---|---|
| **Compilación** | Dependencias con versión exacta, `pubspec.lock` versionado, generación reproducible de plataformas móviles | `pub get`, `analyze --fatal-infos` y demo web ejecutados; Android e iOS en CI |
| **Calidad estática** | `flutter_lints` más cuatro reglas adicionales, validador estructural offline | `analyze --fatal-infos`: 0 hallazgos |
| **Regresión** | 48 pruebas unitarias, de widget y de integración; catálogo de 8 imágenes con manifiesto | `flutter test`: 48/48 |
| **Persistencia** | Esquema idempotente y transaccional, sobres de cifrado versionados | Pruebas de migrador, cifrado y repositorios |
| **Inicio protegido** | Reintento, diagnóstico privado, modo temporal en memoria | Prueba de diagnóstico; fallos nativos requieren dispositivo |
| **Recuperación** | Centro de recuperación con reintento, descarte individual y paquete sin llaves | Prueba de servicio de recuperación |
| **Extensibilidad** | `ScannerEngine`, `ContentParserRegistry` y `FeatureFlags` | Prueba de registro de parsers; segundo motor no se activa |
| **Importación** | Esquema versionado, límites de tamaño, profundidad y nodos, vista previa, duplicados y estrategias | Cuatro pruebas de importación |
| **Accesibilidad** | Alto contraste, controles grandes, movimiento reducido, etiquetas semánticas | Prueba de accesibilidad con texto al 200 %; TalkBack y VoiceOver pendientes |
| **Identidad visual** | Icono generado por código para Android y demo web; diseño adaptable en pantallas móviles grandes | Icono verificado a 48 px y en el lanzador del emulador |
| **Rendimiento** | Límites de lote, cancelación, limpieza de páginas PDF, `compute` para CSV y XLSX, cola serial de inventario | Pruebas de cancelación y cola; medición en hardware pendiente |
| **Seguridad** | AES-256-GCM versionado, metadatos transaccionales, rotación con limpieza, modelo de amenazas, MASVS, SBOM y licencias | Cinco pruebas de cifrado; auditoría independiente pendiente |

## Fuera del alcance

La versión 1.0.0 no incluye firma de artefactos, cuentas de desarrollador,
fichas de tienda, capturas comerciales, AAB, IPA ni despliegue en Google Play o
App Store. Windows, macOS y Linux quedan fuera del alcance del producto; no se
cubren mediante la demo web.

Las capacidades declaradas en [`FEATURE_FLAGS.md`](FEATURE_FLAGS.md) permanecen
apagadas y no forman parte del contrato de esta versión.
