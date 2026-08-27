# 02 · Instalación y ejecución

Todos los comandos de este documento se ejecutan desde la raíz del repositorio.
Ninguno contiene secretos reales.

## Requisitos previos

| Requisito | Versión | Por qué esa versión | Obligatorio |
|---|---|---|---|
| Flutter | **3.44.7** | Fijada en [`../../.fvmrc`](../../.fvmrc) y en los tres workflows de CI. `pubspec.yaml` exige `>=3.44.0` | Sí |
| Dart | `>=3.12.0 <4.0.0` | Declarado en `pubspec.yaml`. Viene con Flutter | Sí |
| Python | 3.12 | Lo usan las 13 herramientas de `tool/` | Sí |
| `uv` | 0.12.5 | Solo lo usa la CI para inyectar `pyyaml` sin instalarlo. En local basta con tener `pyyaml` | No |
| Android SDK | API 24 o superior | `tool/bootstrap.py` fija `minSdk = 24` | Para Android |
| Xcode + macOS | — | Solo un host macOS puede generar y compilar el target iOS | Para iOS |
| Pillow | cualquiera | Solo para **regenerar** los iconos. Compilar no lo necesita | No |

Comprobación rápida del entorno:

```bash
flutter --version
python --version
```

## Por qué hay un paso de generación

**Las carpetas `android/`, `ios/` y `web/` no están en el repositorio.**
`.gitignore` las excluye a propósito. Se generan de forma reproducible con
`tool/bootstrap.py`, que además aplica una lista de parches necesarios:
permisos, iconos, `minSdk`, versiones de la cadena Gradle, textos de uso de
cámara y Face ID, y el cambio de `FlutterActivity` a `FlutterFragmentActivity`
que exige la biometría.

Consecuencia práctica: **un clon recién hecho no compila hasta ejecutar el
bootstrap**.

## Instalación desde cero

```bash
git clone https://github.com/vladimiracunadev-create/rootcause-qr-inspector.git
cd rootcause-qr-inspector
flutter pub get
python tool/bootstrap.py --platforms android,web
```

`--platforms` acepta `android`, `ios` y `web`, separados por comas. Sin el
argumento genera `android` (y también `ios` si el sistema es macOS). El target
`web` existe solo como canal de demostración; no es una plataforma del producto.

En macOS, para trabajar con iOS:

```bash
python tool/bootstrap.py --platforms ios
```

Para regenerar desde cero una carpeta ya existente:

```bash
python tool/bootstrap.py --platforms android --force
```

> **Cuidado:** `--force` borra la carpeta de la plataforma y la vuelve a crear.
> Cualquier cambio hecho a mano dentro de `android/`, `ios/` o `web/` se pierde.
> Esa es justamente la razón de que no se versionen: los cambios deben vivir en
> `tool/bootstrap.py`, no en el resultado.

Atajos equivalentes por sistema:

```bash
./tool/bootstrap.sh --platforms android,web
```

```powershell
.\tool\bootstrap.ps1 -platforms android,web
```

## Variables de entorno

**No identificadas.** El código de la aplicación no lee ninguna variable de
entorno: no hay `String.fromEnvironment`, `--dart-define` ni archivo `.env` en
el repositorio. Toda la configuración de la aplicación vive en las preferencias
del dispositivo y en la política de análisis inyectada por código.

Las únicas variables presentes son de la CI, declaradas en los propios
workflows:

| Variable | Dónde | Valor |
|---|---|---|
| `FLUTTER_VERSION` | los tres workflows | `3.44.7` |
| `DEMO_BASE_HREF` | `deploy-landing.yml` | `/rootcause-qr-inspector/app/` |
| `GH_TOKEN` | `android-release.yml` | El token efímero del propio workflow |

## Configuración inicial

No hay ninguna. La aplicación arranca con valores por defecto conservadores y
crea su base de datos en el primer inicio. Detalle de cada preferencia y su
valor por defecto en [10-configuration.md](10-configuration.md).

## Creación o restauración de la base de datos

**No hay ningún paso manual.** La base se crea sola:

- `AppDatabase.open()` abre el archivo `rootcause_qr_inspector_v2.db` en el
  directorio de soporte de la aplicación (o el almacén IndexedDB del mismo
  nombre en web);
- `SchemaMigrator.migrate()` aplica los pasos de esquema pendientes dentro de
  una transacción, antes de que ningún repositorio la use.

No existe script SQL, ni servidor, ni credenciales de base de datos. Detalle en
[07-database.md](07-database.md).

Para **restaurar** datos de un respaldo se usa la propia aplicación:
Historial → menú → *Importar respaldo JSON*, que muestra una vista previa antes
de tocar nada.

## Ejecución en desarrollo

```bash
flutter run
```

Con un dispositivo o emulador conectado. Para elegir destino:

```bash
flutter devices
flutter run -d <id-del-dispositivo>
```

La demo web:

```bash
flutter run -d chrome
```

En web no están disponibles la lectura de PDF ni el almacén seguro del sistema;
la aplicación lo declara en la interfaz.

## Ejecución en producción

No hay «servidor de producción». Producción es un artefacto instalable.

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

```bash
flutter build web --release
```

```bash
flutter build ios --release
```

> El build de iOS requiere macOS y una identidad de firma. La CI solo compila
> el simulador (`flutter build ios --debug --simulator`), que no necesita firma.

**Importante sobre la firma:** el APK que publica la CI está firmado con la
clave de depuración que genera Flutter, no con una clave comercial. El workflow
lo verifica con `apksigner` y publica su SHA-256, pero eso **no** equivale a una
firma de tienda. Ver [13-deployment-and-operations.md](13-deployment-and-operations.md).

## Ejecución de las pruebas

```bash
flutter test
```

Ejecuta los 87 casos de `test/`. Para cobertura:

```bash
flutter test --coverage
```

Un archivo concreto:

```bash
flutter test test/core/qr_investigation_engine_test.dart
```

La prueba de integración necesita un dispositivo:

```bash
flutter test integration_test/app_launch_test.dart
```

## Verificaciones offline

Estas dos herramientas no necesitan Flutter y son la forma más rápida de saber
si un cambio rompió un contrato del repositorio:

```bash
python tool/validate_structure.py --require-lock
```

Comprueba YAML y JSON válidos, imports locales existentes, enlaces Markdown
locales que resuelven, acciones de GitHub fijadas a SHA, coherencia entre la
versión de `pubspec.yaml` y la que muestra la interfaz, ausencia de rutas
absolutas del entorno, ausencia de registro de contenido sensible, recursos de
la landing, iconos y presencia del lockfile.

```bash
python tool/verify_rootcause_contract.py
```

Comprueba que las 26 reglas del motor existen también en el JSON Schema, en los
textos de la interfaz y en la documentación de heurísticas; que los fixtures
solo usan dominios reservados; que la política de ejemplo es sintética; y que el
contrato de redacción de la evidencia sigue intacto.

En la CI, la primera se ejecuta con `uv` para no depender de un `pyyaml`
instalado:

```bash
uv run --with pyyaml python tool/validate_structure.py --require-lock
```

## Gate completo, igual que la CI

```bash
flutter pub get
python tool/bootstrap.py --platforms android,web
python tool/validate_structure.py --require-lock
python tool/verify_rootcause_contract.py
flutter analyze --fatal-infos
flutter test
flutter build web --release
flutter build apk --release
```

Hay dos scripts que encadenan variantes de esto:

| Script | Para qué |
|---|---|
| `tool/run_quality_gate.sh` | Ciclo de trabajo diario: estructura, análisis, pruebas con cobertura, SBOM y licencias |
| `tool/finalize_stable.sh` | Antes de etiquetar una versión: exige Flutter en PATH, compila, regenera SBOM, licencias y `SOURCE_MANIFEST.json` |

## Errores frecuentes durante la instalación

| Síntoma | Causa | Solución |
|---|---|---|
| `No such file or directory: android/` | No se ejecutó el bootstrap | `python tool/bootstrap.py --platforms android` |
| `Flutter no está instalado o no está disponible en PATH` | El bootstrap necesita Flutter para `flutter create` | Instalar Flutter y reabrir la terminal |
| `cannot find symbol: class FilePickerPlugin` | La plantilla generó AGP 9 y no se aplicaron los parches de la cadena Gradle | Volver a ejecutar el bootstrap, que fija AGP 8.11.1, KGP 2.2.20 y Gradle 8.14.3 |
| `Falta pubspec.lock` | Se ejecutó `validate_structure.py --require-lock` sin resolver | `flutter pub get` y confirmar el lockfile |
| `ModuleNotFoundError: yaml` | `validate_structure.py` y `generate_sbom.py` necesitan `pyyaml` | `pip install pyyaml` o usar `uv run --with pyyaml` |
| Conflicto al resolver `pdfrx` o `excel` | Ambas están ancladas por un conflicto real de `archive` | No subirlas sin leer [`../quality/LOCKFILE.md`](../quality/LOCKFILE.md) |
| `La versión mostrada en la interfaz no coincide` | Se cambió `pubspec.yaml` sin cambiar `lib/core/app_info.dart` | Igualar ambos; es una comprobación deliberada |
| La demo web no lee PDF | El renderizador PDF solo existe en plataformas con `dart:io` | Exportar la página como imagen, o usar una plataforma nativa |

Más síntomas, ya en ejecución, en [14-troubleshooting.md](14-troubleshooting.md).

## Herramientas auxiliares

| Comando | Qué hace | Requiere |
|---|---|---|
| `python tool/generate_sbom.py` | SBOM CycloneDX en `build/reports/sbom.cdx.json` | `pyyaml`; con Flutter incluye el árbol resuelto |
| `python tool/generate_license_inventory.py` | Inventario de licencias de las dependencias | `flutter pub get` previo |
| `python tool/generate_checksums.py <archivo...>` | SHA-256 de cada archivo | — |
| `python tool/generate_source_manifest.py` | Regenera `SOURCE_MANIFEST.json` con el hash de cada archivo fuente | — |
| `python tool/generate_launcher_icons.py` | Regenera los iconos versionados | Pillow |
| `python tool/generate_scan_beep.py` | Regenera el tono de confirmación | — |
| `python tool/build_system_documentation_pdf.py` | Genera los PDF de esta documentación | `markdown`, `xhtml2pdf`; `mmdc` para los diagramas |
