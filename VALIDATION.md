# Estado de validación

**Versión:** 0.1.1+2

**Fecha:** 26 de agosto de 2026
**Fuente derivada:** Universal Code Scanner 1.1.0+2, commit
`c1f98781575bf8223b19ad8344fdfddeaccef373`

Este archivo distingue lo ejecutado sobre **RootCause QR Inspector** de lo que
solo fue validado en la base heredada y de lo que todavía exige hardware o
credenciales de distribución.

## Ejecutado sobre 0.1.1+2 en este entorno

| Comprobación | Comando | Resultado |
|---|---|---|
| Contrato RootCause | `python tool/verify_rootcause_contract.py` | Correcto: 26 ids coherentes entre motor, UI, documentación y JSON Schema; fixtures, política, versión, redacción y frase de seguridad verificadas |
| Estructura del repositorio | `python tool/validate_structure.py --require-lock` | Correcta: YAML/JSON, imports locales, enlaces, versión UI, SBOM y lockfile |
| Sintaxis de herramientas Python | `python -m compileall -q tool` | Correcta |
| Conteo de casos | recuento sobre `test/` e `integration_test/` | 88 casos declarados; 87 los ejecuta `flutter test` |

**No ejecutado en este entorno:** `flutter analyze`, `flutter test` y las
compilaciones. Flutter y Dart no están instalados en la máquina de ensamblado,
así que ninguna afirmación de esta entrega sobre análisis estático, pruebas en
verde o binarios proviene de una ejecución local. La ejecución corresponde a la
CI pública sobre el commit etiquetado.

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

Flutter y Dart no estaban instalados en el entorno local de ensamblado. Por eso
los resultados de aplicación anteriores se atribuyen a la CI pública y no a una
ejecución local. Los verificadores Python sí se ejecutaron localmente.

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
