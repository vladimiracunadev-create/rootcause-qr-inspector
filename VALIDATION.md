# Estado de validación

**Versión:** 0.1.3+4

**Fecha:** 7 de septiembre de 2026
**Fuente derivada:** Universal Code Scanner 1.1.0+2, commit
`c1f98781575bf8223b19ad8344fdfddeaccef373`

Este archivo distingue lo ejecutado sobre **RootCause QR Inspector** de lo que
solo fue validado en la base heredada y de lo que todavía exige hardware o
credenciales de distribución.

## Release 0.1.3 · 7 de septiembre de 2026

| Comprobación | Resultado real |
|---|---|
| `python tool/verify_rootcause_contract.py` | **Correcto:** 26 reglas, esquema, textos, fixtures, política, versión y redacción coherentes |
| `python tool/validate_structure.py --require-lock` | **Correcto:** estructura y lock validados |
| `python -m compileall -q tool` | **Correcto** |
| `flutter analyze --fatal-infos` | **Correcto:** sin issues con Flutter 3.44.7 / Dart 3.12.2 |
| Nuevas pruebas de inspección | **Correcto:** 15 casos de coordinador, destino, persistencia, limpieza PDF y widget |
| `flutter test` | **Correcto:** 103 pruebas aprobadas, incluidas localización y guía de Inventario |
| `flutter build web --release` | **Correcto:** `build/web`; la decodificación de archivos web continúa PLANIFICADA |
| `flutter build apk --release` | **Correcto:** APK release de 92.923.360 bytes, SHA-256 `41b8f1108ad2dcc6f6141ac82fb464dd9f74fd5a6eb0cbbc1469766caa81f0fb` |
| Fixture PNG/PDF | **Parcial:** cuatro fixtures generados; PDF de cinco páginas renderizado y revisado visualmente; falta decodificación con `mobile_scanner` en dispositivo |

Los gates automatizados están verdes. La decodificación nativa de la matriz
completa de fixtures todavía requiere hardware Android y permanece declarada
como validación física pendiente; no se confunde con un fallo del gate de
fuente, pruebas o compilación.

### Idiomas y ayuda contextual

| Comprobación | Resultado real |
|---|---|
| Locales admitidos | Español de Chile/internacional, inglés, francés y alemán registrados en Flutter y seleccionables en Ajustes |
| Persistencia | Cada opción se mapea a un `Locale`; preferencias desconocidas continúan degradando a `system` |
| Datos de la persona | Una prueba widget confirma que una carga no registrada se conserva literalmente al cambiar el idioma |
| Guía de Inventario | Prueba widget a 320×568 y texto al 160 %; contenido completo accesible por desplazamiento y sin overflow |
| Regresión visual | Se mantienen tema, navegación, jerarquía y componentes Material existentes; la ayuda se añade como tarjeta/icono, sin ocultar pestañas |

## Línea base publicada 0.1.2+3

| Comprobación | Comando | Resultado |
|---|---|---|
| Contrato RootCause | `python tool/verify_rootcause_contract.py` | Correcto: 26 ids coherentes entre motor, UI, documentación y JSON Schema; fixtures, política, versión, redacción y frase de seguridad verificadas |
| Estructura del repositorio | `python tool/validate_structure.py --require-lock` | Correcta: YAML/JSON, imports locales, enlaces, versión UI, SBOM y lockfile |
| Sintaxis de herramientas Python | `python -m compileall -q tool` | Correcta |
| Conteo de casos | recuento sobre `test/` e `integration_test/` | 88 casos declarados; 87 los ejecuta `flutter test` |
| Análisis Flutter | `flutter analyze --fatal-infos` | Sin hallazgos |
| Pruebas Flutter | `flutter test` | 87 pruebas aprobadas |
| Web release | `flutter build web --release` | Compilación correcta |
| Demo local | navegador sobre `http://127.0.0.1:8080/` | QR visible; PNG y SVG confirman la descarga sin errores de consola |

La compilación Android, la firma técnica, el checksum y la atestación se repiten
en la CI pública desde el tag `v0.1.2`. La validación física de cámara y ciclo
de vida móvil continúa separada y pendiente.

El generador fija `compileSdk 37`, requisito de `flutter_secure_storage`, y
conserva `minSdk 24` (Android 7). El build local anterior fallaba al heredar el
valor 36 del SDK; tras hacer explícito el contrato reproducible, el mismo host
compiló el APK release indicado arriba. El runner limpio del tag sigue siendo
el gate autoritativo del artefacto publicado.

## Mejora del generador de 0.1.2

| Comportamiento | Evidencia | Límite |
|---|---|---|
| Copiar/compartir contenido no se presenta como descarga | Etiquetas visibles y texto explicativo en `GeneratorScreen` | El portapapeles conserva solo la carga, no la imagen |
| Descargar PNG/SVG en web | Exportador web con `Blob` y enlace de descarga; confirmación funcional en localhost | Depende de que el navegador permita descargas iniciadas por la persona |
| Guardar o compartir en Android/iOS | Exportador nativo conserva `SharePlus` y nombre de archivo | La aplicación receptora la elige el sistema |
| QR sin caducidad propia | Texto visible y documentación de usuario | Un destino o token codificado sí puede expirar |
| Tema visual | Reutiliza botones, tarjetas, colores y tipografía existentes | La validación visual se hizo sobre la demo web, no sustituye la matriz móvil |

## Corrección de lectura de 0.1.1

| Corrección | Qué la respalda | Qué falta |
|---|---|---|
| Detección en toda la imagen (el marco deja de filtrar) | Revisión del código: `MobileScanner` ya no recibe `scanWindow` | Confirmar en teléfono que un código descentrado se lee |
| Resolución de captura declarada (1920×1080 / 1280×720) | `test/features/scanner_engine_config_test.dart` impide volver al valor por defecto | Confirmar en teléfono el alcance real y medir memoria y temperatura en gama baja |
| Relectura del mismo código (`DetectionSpeed.normal`) | Misma prueba de configuración; filtro de repetición con aviso en pantalla | Confirmar el ciclo leer → cerrar → volver a leer en dispositivo |
| Estado `Código leído` | `test/features/scan_status_bar_test.dart` verifica título y barra llena | Captura de pantalla real del estado en Android |
| Tono precalentado y no bloqueante | `test/services/scan_feedback_test.dart` cubre `warmUp` y su degradación | Confirmar latencia audible en dispositivo |
| Conteo de unidades repetidas en inventario | Revisión del código: mismo cambio de detector | Contar diez unidades iguales en un teléfono |

Ninguna prueba automatizada puede demostrar que un QR lejano se lee con una
cámara real. Las pruebas añadidas impiden una regresión de configuración; no
sustituyen la matriz de dispositivos.

No se ejecutó un validador de metaschema Draft 2020-12 independiente; el
verificador offline sí comprueba el dialecto, los 26 ids, las referencias de
fixtures y las restricciones de redacción específicas del contrato.

## Validación pública de la aplicación (0.1.1)

Ejecución de GitHub Actions
[`33029927460`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/actions/runs/33029927460)
sobre el commit `a7ebf2c`:

| Gate | Resultado |
|---|---|
| Estructura y contrato offline | Correctos |
| `flutter analyze --fatal-infos` | Sin hallazgos |
| `flutter test --coverage` | Verde |
| `flutter build web --release` | Correcto |
| `flutter build apk --release` | Correcto |
| `flutter build ios --debug --simulator` | Correcto |

La ejecución anterior sobre el mismo cambio,
[`33029682079`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/actions/runs/33029682079),
falló con un único `undefined_class` y bloqueó la publicación. Se conserva el
dato porque demuestra que el gate hace su trabajo.

El workflow de publicación
[`33041878441`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/actions/runs/33041878441)
verificó la versión del tag, repitió análisis y pruebas, compiló el APK,
comprobó su firma con `apksigner`, atestó su procedencia y publicó el Release.

Comprobación del artefacto **después** de publicarlo, en este equipo:

| Comprobación | Resultado |
|---|---|
| Tamaño del APK | 92 792 108 bytes |
| SHA-256 recalculado en local | `dbe881d6…d7d7`, coincide con el publicado |
| Contenido del paquete | 529 entradas, con `classes.dex`, los assets de Flutter y las bibliotecas nativas |
| `sha256sum -c` | Correcto tras corregir el fichero de checksums, que llevaba la ruta interna de CI |

## Validación pública de la aplicación (0.1.0)

> Registro de la entrega anterior. La ejecución equivalente para 0.1.1 es la que
> dispare el tag `v0.1.1`.

La ejecución pública de GitHub Actions
[`32543327067`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/actions/runs/32543327067)
terminó en verde sobre el commit `2da6534`:

| Gate | Resultado |
|---|---|
| Resolución reproducible | `flutter pub get --enforce-lockfile` correcto |
| Análisis estático | `flutter analyze --fatal-infos` sin hallazgos |
| Pruebas | 77 casos Dart/Flutter en verde |
| Web / PWA | build release correcto |
| Android | APK de depuración correcto, checksum y artefacto publicados por CI |
| iOS | build debug para simulador correcto, sin identidad de firma |
| macOS | build debug correcto |

El despliegue de Pages
[`32543327044`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/actions/runs/32543327044)
también terminó en verde y publicó la landing y la PWA.

## Cobertura de la suite

El repositorio declara 88 casos Dart/Flutter entre pruebas unitarias, widgets e
integración; `flutter test` ejecuta los 87 de `test/`, y el caso de
`integration_test/` requiere dispositivo. Diecinueve cubren específicamente el
contrato de investigación o sus fronteras:

- motor QR: HTTPS neutro, huella exacta, HTTP, Punycode, `userinfo`, esquema
  ejecutable, control codificado en `mailto:`, URL anidada, APK, IPv4 privada,
  excepción de dominio `fc*`, pagos y política de marca;
- evidencia: omisión completa de carga/URL, alteración, inclusión explícita,
  reordenamiento de claves y validación del enlace anterior;
- importación no confiable: recalcula id, hallazgos y decisión en vez de aceptar
  campos derivados del respaldo;
- privacidad: una URL con token se clasifica como sensible antes de decidir su
  persistencia.

Seis casos añadidos en 0.1.1 cubren la interacción de la cámara: el estado
`Código leído`, el precalentado del tono y su degradación, y la configuración
del motor de captura.

Los resultados de 0.1.3 indicados al inicio provienen de una ejecución local con
Flutter 3.44.7. Las validaciones públicas históricas conservan sus propios
enlaces y alcance.

## Heredado y verificado en la fuente

Universal Code Scanner 1.1.0+2 documenta, en el commit de procedencia:

- resolución de dependencias y lockfile;
- análisis estático sin hallazgos;
- 57 pruebas en verde;
- build Android y web;
- arranque Android en emulador;
- CI para Android, web, iOS y macOS.

Eso da confianza en el sustrato, pero **no sustituye** la validación de los
cambios RootCause. El detalle histórico se conserva mediante el enlace al
repositorio original en [`docs/rootcause/PROVENANCE.md`](docs/rootcause/PROVENANCE.md).

## Gate reproducible antes de un release binario

```bash
flutter pub get
python3 tool/bootstrap.py --platforms android,web
python3 tool/validate_structure.py --require-lock
python3 tool/verify_rootcause_contract.py
flutter analyze --fatal-infos
flutter test
flutter build web --release
flutter build apk --release
```

La CI ya satisface estos gates de código y compilación. Antes de un release deben
probarse en dispositivo físico la cámara, ciclo de vida, poca luz, biometría,
almacenamiento seguro y apertura externa. Para distribución se requieren además
firma, perfiles y cuentas de tienda.

## Criterio de honestidad

Una validación estructural demuestra coherencia documental y de archivos. No
demuestra comportamiento en runtime. Una prueba Flutter demuestra el caso
codificado. Ninguna de las dos demuestra que un destino escaneado sea seguro.
