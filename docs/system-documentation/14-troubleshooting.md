# 14 · Solución de problemas

Cada entrada sigue el mismo formato: síntoma, causa posible, diagnóstico,
solución, archivos relacionados y riesgo de aplicar la solución.

Esta guía cubre el punto de vista de quien **desarrolla y opera**. La guía
orientada a quien **usa** la aplicación está en
[`../TROUBLESHOOTING.md`](../TROUBLESHOOTING.md).

---

## Instalación y compilación

### `No such file or directory: android/`

| Aspecto | Detalle |
|---|---|
| **Causa** | Las carpetas nativas no se versionan; hay que generarlas |
| **Diagnóstico** | `ls android ios web` no encuentra nada |
| **Solución** | `python tool/bootstrap.py --platforms android,web` |
| **Archivos** | `tool/bootstrap.py`, `.gitignore` |
| **Riesgo** | Ninguno. Con `--force` sí: borra y regenera, y pierde cambios hechos a mano |

### `cannot find symbol: class FilePickerPlugin`

| Aspecto | Detalle |
|---|---|
| **Causa** | La plantilla de Flutter 3.44.7 genera AGP 9. Varios plugins dejan de aplicar el Kotlin Gradle Plugin al detectarlo, dando por hecho el Kotlin integrado, pero la misma plantilla entrega `android.builtInKotlin=false`: nadie compila su Kotlin |
| **Diagnóstico** | `grep 'com.android.application' android/settings.gradle.kts` muestra una versión 9.x |
| **Solución** | Volver a ejecutar el bootstrap, que fija AGP 8.11.1, KGP 2.2.20 y Gradle 8.14.3 |
| **Archivos** | `tool/bootstrap.py` (`patch_android_toolchain`) |
| **Riesgo** | Activar el Kotlin integrado rompe el caso contrario, en los plugins que sí aplican KGP |

### `Falta pubspec.lock`

| Aspecto | Detalle |
|---|---|
| **Causa** | `--require-lock` exige el lockfile versionado |
| **Diagnóstico** | `ls pubspec.lock` |
| **Solución** | `flutter pub get` con la versión fijada y confirmar el archivo |
| **Riesgo** | Regenerarlo con otra versión de Flutter puede mover dependencias transitivas |

### `ModuleNotFoundError: yaml`

| Aspecto | Detalle |
|---|---|
| **Causa** | `validate_structure.py` y `generate_sbom.py` necesitan `pyyaml` |
| **Solución** | `pip install pyyaml`, o `uv run --with pyyaml python tool/...` como hace la CI |
| **Riesgo** | Ninguno |

### Conflicto al resolver `pdfrx` o `excel`

| Aspecto | Detalle |
|---|---|
| **Causa** | `pdfrx` ≥ 2.4.6 arrastra `archive ^4`, incompatible con el `archive ^3.6.1` que exige `excel 4.0.6` |
| **Diagnóstico** | `flutter pub get` falla en la resolución |
| **Solución** | Mantener los anclajes. `flutter pub outdated` los mostrará como actualizables: es esperado |
| **Archivos** | `pubspec.yaml`, `.github/dependabot.yml`, [`../quality/LOCKFILE.md`](../quality/LOCKFILE.md) |
| **Riesgo** | Subirlos sin resolver el conflicto rompe la compilación |

---

## Gates y verificadores

### `La versión mostrada en la interfaz no coincide con pubspec.yaml`

| Aspecto | Detalle |
|---|---|
| **Causa** | Se cambió `pubspec.yaml` sin cambiar `lib/core/app_info.dart` |
| **Solución** | Igualar ambos valores |
| **Riesgo** | Ninguno. La comprobación existe porque esa deriva ya ocurrió antes |

### `El motor 0.1.0 debe declarar 26 reglas; encontró N`

| Aspecto | Detalle |
|---|---|
| **Causa** | Se añadió o quitó una llamada a `evaluate('...')` |
| **Solución** | Completar la entrega: motor, `QrFindingText`, esquema, `HEURISTICS.md`, fixture, pruebas y `engineVersion`. Si el número cambia a propósito, actualizar también el verificador |
| **Archivos** | `tool/verify_rootcause_contract.py`, motor, textos, esquema, heurísticas |
| **Riesgo** | Cambiar solo el verificador para que pase **oculta** una regla huérfana |

### `Desalineación motor↔schema` o `motor↔textos`

| Aspecto | Detalle |
|---|---|
| **Causa** | Un id existe en un archivo y no en los demás |
| **Diagnóstico** | El mensaje lista qué falta y qué sobra |
| **Solución** | Añadir el id al esquema y a `QrFindingText.title` |
| **Riesgo** | Un id sin texto se muestra crudo en la interfaz |

### `Enlace Markdown local inexistente`

| Aspecto | Detalle |
|---|---|
| **Causa** | Un enlace relativo apunta a un archivo que no existe |
| **Diagnóstico** | El mensaje da archivo y destino |
| **Solución** | Corregir la ruta o crear el archivo |
| **Riesgo** | Ninguno. Este gate es lo que mantiene la documentación navegable |

### `Action no fijada a commit SHA`

| Aspecto | Detalle |
|---|---|
| **Causa** | Se usó `uses: org/action@v1` en vez del SHA de 40 caracteres |
| **Solución** | Fijar el SHA y dejar la versión legible en un comentario |
| **Riesgo** | Una etiqueta móvil puede cambiar bajo los pies y ejecutar otro código |

### `undefined_class` u otro error de `flutter analyze`

| Aspecto | Detalle |
|---|---|
| **Causa** | `--fatal-infos` convierte cualquier hallazgo en error |
| **Diagnóstico** | `flutter analyze --fatal-infos` en local; en CI, `gh run view <id> --log-failed` |
| **Solución** | Corregir el hallazgo |
| **Riesgo** | Relajar `analysis_options.yaml` debilita el gate para todo el repositorio |

> Ocurrió en esta versión: sustituir `package:flutter/foundation.dart` por
> `package:flutter/widgets.dart` dejó `ValueListenable` sin definir, porque
> `widgets.dart` reexporta `Size` pero no ese tipo. La CI lo detectó y bloqueó
> la publicación, que es exactamente lo que debe hacer.

---

## Cámara y lectura

### La cámara no arranca

| Aspecto | Detalle |
|---|---|
| **Causa** | Permiso denegado, dispositivo sin cámara compatible, u otra aplicación ocupándola |
| **Diagnóstico** | La barra muestra `Sensor no disponible` con el mensaje específico. El de permiso es distinto del genérico |
| **Solución** | Conceder el permiso, cerrar la otra aplicación, o pulsar «Reintentar», que reconstruye el controlador |
| **Archivos** | `scanner_screen.dart` (`_startCamera`, `_restartCamera`, `_describe`) |
| **Riesgo** | Ninguno: reiniciar libera la sesión de cámara antes de crear la nueva |

### La vista previa se queda congelada al volver del segundo plano

| Aspecto | Detalle |
|---|---|
| **Causa** | `MobileScanner` solo gestiona el ciclo de vida cuando él crea el controlador. Aquí lo crea la pantalla |
| **Diagnóstico** | La imagen no se actualiza tras volver de otra aplicación |
| **Solución** | Ya está resuelto: ambas pantallas con cámara observan `didChangeAppLifecycleState`. Si reaparece, comprobar que ese método no se eliminó |
| **Archivos** | `scanner_screen.dart`, `inventory_screen.dart` |
| **Riesgo** | Quitar la observación reintroduce el fallo original |

### Un código legible no se lee

| Aspecto | Detalle |
|---|---|
| **Causa 1** | Resolución insuficiente para un código lejano |
| **Causa 2** | Antes de 0.1.1, el marco filtraba la detección y descartaba en silencio lo que quedara fuera |
| **Diagnóstico** | Acercarse: si a 20 cm sí lee, es alcance. Descentrar el código: si deja de leer, el marco está filtrando |
| **Solución** | Acercarse o usar el zoom. Comprobar que `MobileScanner` **no** recibe `scanWindow` y que `cameraResolution` está declarada |
| **Archivos** | `mobile_scanner_engine.dart`, `scanner_screen.dart`, `test/features/scanner_engine_config_test.dart` |
| **Riesgo** | Subir la resolución aumenta memoria y temperatura en gama baja: medir antes |

### La barra dice «Ese código ya se inspeccionó»

| Aspecto | Detalle |
|---|---|
| **Causa** | Es el filtro de repetición, no un fallo |
| **Diagnóstico** | El aviso aparece mientras el mismo código sigue delante del lente |
| **Solución** | Apartar la cámara unos segundos y volver a apuntar, o pulsar «Reiniciar cámara», que limpia la firma |
| **Archivos** | `scanner_screen.dart` (`_repeatWindow`, `_showRepeatNotice`) |
| **Riesgo** | Quitar el filtro reabre el resultado en bucle mientras el código esté a la vista |

### El inventario no suma unidades repetidas

| Aspecto | Detalle |
|---|---|
| **Causa** | `DetectionSpeed.noDuplicates` impedía emitir el mismo código dos veces |
| **Diagnóstico** | Escanear diez veces el mismo producto y contar |
| **Solución** | Corregido en 0.1.1 con `DetectionSpeed.normal`. Verificar que el controlador del inventario no volvió a `noDuplicates` |
| **Archivos** | `inventory_screen.dart` (`_createController`, `_onDetect`) |
| **Riesgo** | Sin el filtro de 1200 ms de `_onDetect`, una caja se contaría en cada cuadro |

### No suena el tono de confirmación

| Aspecto | Detalle |
|---|---|
| **Causa 1** | `sound_enabled` desactivado |
| **Causa 2** | El reproductor falló y degradó a `SystemSound.play`, que Android silencia si los sonidos táctiles están apagados |
| **Diagnóstico** | Comprobar Ajustes. En pruebas, `ScanFeedback.toneUnavailable` indica la degradación |
| **Solución** | Activar el sonido; comprobar que el asset sigue declarado en `pubspec.yaml` |
| **Archivos** | `scan_feedback.dart`, `assets/sounds/scan_success.wav` |
| **Riesgo** | Ninguno: el fallo del audio nunca interrumpe una lectura |

---

## Datos, cifrado y recuperación

### Un registro aparece aislado en el Centro de recuperación

| Aspecto | Detalle |
|---|---|
| **Causa** | El sobre no se pudo descifrar: llave ausente o carga manipulada |
| **Diagnóstico** | El código de la incidencia: `decrypt_StateError` suele ser llave ausente; otro tipo apunta a manipulación |
| **Solución** | «Reintentar recuperación». Si falla, descartar solo ese registro |
| **Archivos** | `recovery_service.dart`, `payload_cipher.dart` |
| **Riesgo** | Descartar es **irreversible** para ese registro. **No editar la base a mano** |

### `encryption_key_missing:<keyId>`

| Aspecto | Detalle |
|---|---|
| **Causa** | La llave de ese sobre no está en el almacén seguro. Suele ocurrir tras reinstalar o restaurar en otro dispositivo |
| **Diagnóstico** | El identificador indica cuál falta |
| **Solución** | No hay recuperación posible sin la llave. Descartar los registros afectados o rotar la llave para el contenido que sí se lee |
| **Riesgo** | **Nunca** cambiar el código para que el descifrado use `readOrCreate`: crearía una llave nueva y perdería todo lo anterior en silencio |

### La rotación de llave falla

| Aspecto | Detalle |
|---|---|
| **Causa** | Un registro incompleto (`history_payload_missing:<id>`), un descifrado imposible, u otra rotación en curso |
| **Diagnóstico** | El mensaje de la excepción nombra el registro |
| **Solución** | Resolver ese registro en el Centro de recuperación y volver a rotar |
| **Archivos** | `data_maintenance_service.dart` |
| **Riesgo** | Ninguno para los datos: la transacción se revierte y la llave nueva se borra |

### El historial aparece vacío

| Aspecto | Detalle |
|---|---|
| **Causa 1** | `private_mode` activo o `save_history` desactivado |
| **Causa 2** | Modo temporal: nada persiste |
| **Causa 3** | Retención configurada que ya podó |
| **Causa 4** | Solo se escanearon contenidos sensibles, que no se guardan |
| **Diagnóstico** | Revisar Ajustes y el banner de modo temporal |
| **Solución** | Ajustar las preferencias |
| **Riesgo** | La poda por retención es **irreversible** |

### La migración del historial heredado no termina

| Aspecto | Detalle |
|---|---|
| **Causa** | El origen no es una lista válida, o la verificación posterior a la escritura falló |
| **Diagnóstico** | `history_migration_error` y una incidencia con `entityId: history_v1_to_v2` |
| **Solución** | Ajustes → «Reintentar migración del historial» |
| **Archivos** | `history_repository.dart` (`_migrateLegacyHistory`) |
| **Riesgo** | Ninguno: el origen y su respaldo cifrado se conservan hasta que la verificación pasa |

### La aplicación arranca en «Inicio seguro»

| Aspecto | Detalle |
|---|---|
| **Causa** | Falló abrir la base, leer preferencias o el almacén seguro |
| **Diagnóstico** | La pantalla muestra tipo de error y huella de pila. «Copiar diagnóstico privado» da el detalle sin cargas |
| **Solución** | Reintentar; si persiste, abrir sin datos persistentes para seguir trabajando; restablecer preferencias visuales |
| **Riesgo** | El modo temporal **no conserva nada** de esa sesión |

---

## Importación y exportación

### `El respaldo no es válido o no pudo leerse`

| Aspecto | Detalle |
|---|---|
| **Causa** | Tamaño, forma, aplicación no compatible, tipo incorrecto, versión futura o exceso de registros |
| **Diagnóstico** | El mensaje de la interfaz es genérico; el detalle está en el `FormatException` |
| **Solución** | Comprobar que el archivo lleva `application`, `type` y `schemaVersion` correctos |
| **Archivos** | `import_service.dart` |
| **Riesgo** | Ninguno: nada se escribe hasta elegir la estrategia |

### La importación descarta registros

| Aspecto | Detalle |
|---|---|
| **Causa** | Cada registro se **recalcula**; los que fallan se cuentan como rechazados |
| **Diagnóstico** | La vista previa muestra válidos, duplicados y rechazados |
| **Solución** | Es el comportamiento correcto: un respaldo no puede imponer campos derivados |
| **Riesgo** | «Reemplazar» sustituye la base completa. Preferir «Combinar» u «Omitir duplicados» |

### El CSV exportado se ve mal en la hoja de cálculo

| Aspecto | Detalle |
|---|---|
| **Causa** | Codificación o separador |
| **Diagnóstico** | El archivo se escribe con BOM UTF-8 y todas las celdas entrecomilladas |
| **Solución** | Importarlo indicando UTF-8 y coma como separador |
| **Archivos** | `export_service.dart` (`_encodeCsv`) |
| **Riesgo** | Recordar que el CSV **contiene las cargas en claro** |

---

## Demo web

### El PDF no se procesa

| Aspecto | Detalle |
|---|---|
| **Causa** | El renderizador solo existe con `dart:io` |
| **Solución** | Exportar la página como imagen, o usar una plataforma nativa |
| **Archivos** | `pdf_page_renderer_stub.dart` |
| **Riesgo** | Ninguno |

### Página vacía o recursos 404

| Aspecto | Detalle |
|---|---|
| **Causa** | Ruta incompleta, o un service worker de una versión anterior |
| **Solución** | Abrir la ruta completa `/rootcause-qr-inspector/app/`, forzar recarga o borrar los datos del sitio |
| **Archivos** | `.github/workflows/deploy-landing.yml` |
| **Riesgo** | Ninguno |

---

## Documentación y PDF

### `python tool/build_system_documentation_pdf.py` se detiene

| Aspecto | Detalle |
|---|---|
| **Causa** | Falta `markdown` o `xhtml2pdf` |
| **Solución** | `pip install markdown xhtml2pdf` |
| **Riesgo** | Ninguno |

### Los diagramas salen como texto

| Aspecto | Detalle |
|---|---|
| **Causa** | `mmdc` no está instalado; el script degrada con aviso |
| **Solución** | `npm install -g @mermaid-js/mermaid-cli` |
| **Riesgo** | Ninguno: sin `mmdc` el PDF sigue generándose, con los diagramas como bloque de código |

### Caracteres corruptos: `mÃ¡s`, `Ã³`

| Aspecto | Detalle |
|---|---|
| **Causa** | Doble codificación UTF-8, típica al escribir desde una consola de Windows sin fijar la codificación |
| **Diagnóstico** | `grep -rl $'\xc3\x83' docs/` |
| **Solución** | Reescribir el archivo leyendo y escribiendo con `encoding="utf-8"` explícito |
| **Riesgo** | Ninguno, pero conviene revisar el archivo entero |

---

## Comandos útiles de diagnóstico

```bash
python tool/validate_structure.py --require-lock
python tool/verify_rootcause_contract.py
flutter analyze --fatal-infos
flutter test
gh run list --branch main --limit 5
gh run view <id> --log-failed
gh release view v0.1.1 --json assets
sha256sum -c rootcause-qr-inspector-v0.1.1-android.apk.sha256
grep -rn "package:flutter" lib/core/investigation/
grep -rn "http\.get\|HttpClient\|WebSocket" lib/
```
