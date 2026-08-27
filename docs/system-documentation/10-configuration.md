# 10 · Configuración

## Dónde vive la configuración

Hay cuatro lugares, y conviene no confundirlos:

| Lugar | Qué configura | Quién lo cambia | Persistente |
|---|---|---|---|
| Preferencias del dispositivo | Comportamiento de la aplicación | La persona, desde Ajustes | Sí |
| `QrAnalysisPolicy` | Umbrales y marcas del motor | Un integrador, por código | No: se pasa en cada llamada |
| Archivos del repositorio | Compilación y publicación | Quien desarrolla | Sí, versionado |
| Variables de entorno | **Nada en la aplicación** | — | — |

**Comprobado:** no hay `String.fromEnvironment`, `--dart-define` ni archivo
`.env` en el repositorio. La aplicación no lee ninguna variable de entorno.

## Preferencias

Se guardan con `SharedPreferencesAsync` —no en la base cifrada— porque ninguna
contiene carga escaneada. Cada lectura aplica un valor por defecto, así que una
clave ausente o corrupta nunca deja la aplicación sin configuración.

### Apariencia y accesibilidad

| Clave | Tipo | Por defecto | Efecto | Consecuencia de un valor incorrecto |
|---|---|---|---|---|
| `theme_mode` | `system`/`light`/`dark` | `system` | Tema claro u oscuro | Un valor desconocido cae a `system` |
| `language` | `system`/`esCl`/`es`/`en` | `system` | Idioma de la interfaz | `en` existe pero **no se ofrece**; el desplegable lo muestra como «Sistema» |
| `high_contrast` | bool | `false` | Sube el contraste y marca los bordes de tarjeta | Ninguna: es visual |
| `large_controls` | bool | `false` | Aumenta la densidad táctil **sin** tocar la escala tipográfica | Ninguna |
| `reduce_motion` | bool | `false` | Elimina transiciones; la barra de estado se dibuja llena y quieta y el marco no barre | Ninguna |

### Inspección

| Clave | Tipo | Por defecto | Efecto | Consecuencia de un valor incorrecto |
|---|---|---|---|---|
| `use_scan_window` | bool | `true` | Dibuja el marco de encuadre. **Es solo visual**: la lectura analiza toda la imagen | Ninguna sobre la detección. Antes de 0.1.1 sí filtraba, y descartaba códigos en silencio |
| `auto_torch` | bool | `false` | Enciende la linterna al iniciar la cámara | Consumo de batería |
| `sound_enabled` | bool | `true` | Tono de confirmación al leer | Desactivarlo deja la confirmación en la vibración y el estado visible |
| `vibration_enabled` | bool | `true` | Vibración `heavyImpact` al leer | Igual que el anterior |

> Desactivar **sonido y vibración a la vez** deja la confirmación de lectura
> únicamente en el estado visible `Código leído` y en la apertura del resultado.

### Privacidad y seguridad

| Clave | Tipo | Por defecto | Efecto | Consecuencia de un valor incorrecto |
|---|---|---|---|---|
| `save_history` | bool | `true` | Guarda las lecturas no sensibles | En `false` no se conserva nada; los resultados siguen mostrándose |
| `private_mode` | bool | `false` | Mientras esté activo, **ninguna** lectura se guarda | Se puede confundir con «no funciona el historial» |
| `hide_sensitive_values` | bool | `true` | Oculta contraseña, secreto, consulta, dirección, IBAN y carga tras `••••••••` | En `false` los valores sensibles se muestran directamente en pantalla |
| `confirm_before_open` | bool | `true` | Exige confirmación antes de entregar una URI | En `false` sigue habiendo confirmación si el motor decide `confirm` o si el riesgo no es bajo |
| `biometric_lock` | bool | `false` | Bloquea la aplicación al perder el primer plano | Solo se activa si la autenticación tiene éxito en ese momento |
| `clear_clipboard_seconds` | int | `30` | Borra el portapapeles si no cambió. Valores ofrecidos: 0, 15, 30, 60, 300 | `0` significa **nunca borrar** |
| `history_retention_days` | int | `0` | Elimina lecturas más antiguas al arrancar y al cambiar la opción. Valores: 0, 30, 90, 365 | `0` significa **sin límite**, no «borrar todo» |

### Banderas de capacidades

`feature_flags` se guarda como JSON con nueve booleanos, todos `false`:

`experimentalParsers`, `secondaryScannerEngine`, `ocr`, `nfc`, `urlReputation`,
`productLookup`, `encryptedSync`, `enterpriseApi`, `kioskMode`.

**Estado comprobado:** ninguna bandera se lee en `lib/`. Se serializan y
deserializan, pero no cambian comportamiento. Son un contrato de reserva; su
regla, en [`../quality/FEATURE_FLAGS.md`](../quality/FEATURE_FLAGS.md), es que
activar una nunca debe cambiar el formato persistente.

Si el JSON está corrupto, la lectura cae a `const FeatureFlags()` dentro de un
`try`: todas apagadas.

### Claves internas, no visibles en Ajustes

| Clave | Para qué |
|---|---|
| `scan_history_v1` | Historial heredado en claro. Se migra y se borra |
| `scan_history_v1_backup` | Respaldo **cifrado** del origen heredado |
| `history_migrated_to_v2` | Marca de migración completada |
| `history_migration_error` | Código del último fallo de migración |
| `encryption_active_key_id` | Valor heredado; se traslada a la base y se borra de aquí |

### Restablecer preferencias

`SettingsRepository.resetNonSensitive` —la opción «Restablecer preferencias
visuales» del arranque seguro— borra 14 claves y **conserva deliberadamente
tres**:

| Clave conservada | Por qué |
|---|---|
| `save_history` | Su valor por defecto es «guardar» |
| `private_mode` | Su valor por defecto es «no privado» |
| `biometric_lock` | Su valor por defecto es «sin bloqueo» |

Restablecerlas relajaría la postura de privacidad que la persona había elegido.
Las que sí se restablecen —como `hide_sensitive_values` o `confirm_before_open`—
vuelven a un valor **más** conservador, no menos.

## Política de análisis

`QrAnalysisPolicy` parametriza el motor sin tocar su código.

| Campo | Por defecto | Regla afectada | Consecuencia de subirlo o bajarlo |
|---|---|---|---|
| `maxUrlLength` | `240` | `url-excessive-length` | Muy alto: nunca dispara. Muy bajo: ruido en URL legítimas largas |
| `maxDomainLabels` | `5` | `host-deep-subdomains` | Muy bajo: falsos positivos en infraestructura corporativa |
| `allowPrivateTargets` | `false` | `host-private-or-local` | **En `true` silencia una señal crítica.** Solo tiene sentido en despliegues internos donde un panel en `192.168.x.x` es el destino esperado |
| `trustedBrands` | `[]` | `brand-domain-mismatch` | Sin marcas, la regla nunca dispara |

Cada `QrTrustedBrand` declara `id`, `tokens` y `allowedHosts`. Los tokens se
comparan reducidos a letras y dígitos, así que `banco-ejemplo` también detecta
`bancoejemplo`. Un token con menos de cuatro caracteres alfanuméricos se ignora,
para no disparar la regla con fragmentos genéricos.

### Cómo se inyecta hoy

```dart
const QrAnalysisPolicy policy = QrAnalysisPolicy(
  maxUrlLength: 300,
  trustedBrands: <QrTrustedBrand>[
    QrTrustedBrand(
      id: 'banco-ejemplo',
      tokens: <String>['banco-ejemplo'],
      allowedHosts: <String>['banco-ejemplo.example'],
    ),
  ],
);

final QrInvestigation resultado = QrInvestigationEngine.analyze(
  carga,
  parsed: ContentInterpreter.parse(carga),
  policy: policy,
);
```

> **Límite declarado.** La aplicación **no carga**
> `config/rootcause-qr-policy.example.json` en tiempo de ejecución. No existe
> pantalla para importar, firmar ni administrar una política. El archivo es un
> contrato de referencia para integradores, y `QrAnalysisPolicy.fromJson` existe
> para consumirlo desde código propio.

## Diferencias entre entornos

**No hay entornos.** No existen perfiles de desarrollo, pruebas y producción, ni
sabores de compilación, ni configuración condicional por entorno. La misma
aplicación se comporta igual en depuración y en release.

Las únicas diferencias reales son de **plataforma**, y se resuelven en
compilación:

| Diferencia | Nativo | Web (demo) |
|---|---|---|
| Base de datos | Archivo Sembast | IndexedDB |
| Lectura de PDF | Disponible | `UnsupportedError`; la opción se oculta |
| Almacén de llaves | Keychain / Keystore | Lo que ofrezca el navegador |
| Menú de imagen y PDF | Habilitado | Deshabilitado (`enabled: !kIsWeb`) |

## Configuración de compilación y publicación

| Archivo | Qué fija | Cambiarlo implica |
|---|---|---|
| `pubspec.yaml` | Versión, dependencias, assets | La versión debe igualarse en `lib/core/app_info.dart` o falla la validación |
| `.fvmrc` | Flutter 3.44.7 | Debe cambiarse a la vez que `FLUTTER_VERSION` en los tres workflows |
| `analysis_options.yaml` | `flutter_lints` más `always_declare_return_types`, `avoid_print`, `prefer_final_locals`, `use_build_context_synchronously` | Relajarlo debilita el gate de CI |
| `.gitattributes` | LF en todo el texto | Necesario para que los hashes de `SOURCE_MANIFEST.json` sigan siendo verificables tras clonar en Windows |
| `.github/dependabot.yml` | `pdfrx` bloqueado por encima de 2.4.5 | Ver [`../quality/LOCKFILE.md`](../quality/LOCKFILE.md) antes de levantarlo |

### Constantes fijadas en `tool/bootstrap.py`

| Constante | Valor | Por qué |
|---|---|---|
| `ANDROID_GRADLE_PLUGIN` | `8.11.1` | La plantilla de Flutter 3.44.7 genera AGP 9, cuyo Kotlin integrado rompe varios plugins de este conjunto |
| `KOTLIN_GRADLE_PLUGIN` | `2.2.20` | Mínimo que Flutter 3.44.7 no marca obsoleto |
| `GRADLE_DISTRIBUTION` | `8.14.3` | Compatible con AGP 8.11.1 |
| `minSdk` | `24` | Android 7.0 |
| Plataforma iOS | `15.5` | Podfile, proyecto y `AppFrameworkInfo.plist` |
| `PRODUCT_PLATFORMS` | `("android", "ios")` | `validate_structure.py` falla si cambia |
| `GENERATABLE_TARGETS` | `(*PRODUCT_PLATFORMS, "web")` | Mantiene web separado como canal de demostración |

Las dos últimas están **verificadas por el validador estructural**: es una
barrera deliberada para que el escritorio no vuelva a presentarse como
plataforma del producto.

## Configuraciones sensibles

| Configuración | Riesgo si se cambia sin criterio |
|---|---|
| `allowPrivateTargets: true` | Silencia `host-private-or-local`, una señal crítica |
| `hide_sensitive_values: false` | Contraseñas y secretos visibles en pantalla, y en cualquier captura |
| `clear_clipboard_seconds: 0` | Una carga sensible permanece en el portapapeles indefinidamente |
| `private_mode: false` con historial activo | Se conservan lecturas que quizá no se querían conservar |
| `confirm_before_open: false` | Reduce las barreras, aunque el motor mantiene las suyas |
| Relajar `analysis_options.yaml` | Debilita el gate que la CI aplica con `--fatal-infos` |
| `android:allowBackup` a `true` | La base entraría en la copia del sistema; la llave no viajaría con ella |

## Secretos

**Comprobado: no hay ningún secreto en el repositorio.** No hay claves de API,
tokens, contraseñas ni certificados. Las razones son estructurales: no hay
servicios remotos que autenticar, y la firma del APK usa la clave de depuración
que genera Flutter.

Los únicos valores con forma de secreto son sintéticos y aparecen en fixtures y
documentación con dominios reservados:

| Valor | Dónde | Naturaleza |
|---|---|---|
| `otpauth://totp/Ejemplo?secret=SYNTHETIC123` | `fixtures/qr/manifest.json` | Cadena inventada |
| `bitcoin:bc1qexample?amount=0.01` | fixtures | Dirección inválida a propósito |
| `banco-ejemplo.example` | política de ejemplo | TLD reservado |
| `https://example.com/...` | pruebas y generador | Dominio reservado |

El único secreto real del sistema —la llave de cifrado— se genera en el
dispositivo, vive en Keychain/Keystore y **nunca** se escribe en el repositorio,
en un export ni en un diagnóstico.

`tool/validate_structure.py` incluye `check_sensitive_logging`, que falla si
aparece una llamada a `print`, `debugPrint` o `log` cuyo argumento mencione
`rawValue`, `password`, `secret`, `otp` o `payload`.
