# Estado de validación

**Versión:** 0.1.0+1

**Fecha:** 21 de agosto de 2026
**Fuente derivada:** Universal Code Scanner 1.1.0+2, commit
`c1f98781575bf8223b19ad8344fdfddeaccef373`

Este archivo distingue lo ejecutado sobre **RootCause QR Inspector** de lo que
solo fue validado en la base heredada. No se atribuye a esta derivación una
compilación que todavía no se ejecutó.

## Ejecutado sobre 0.1.0+1 en este entorno

| Comprobación | Comando | Resultado |
|---|---|---|
| Contrato RootCause | `python3 tool/verify_rootcause_contract.py` | Correcto: 26 ids coherentes entre motor, UI, documentación y JSON Schema; fixtures, política, versión, redacción y frase de seguridad verificadas |
| Estructura del repositorio | `python3 tool/validate_structure.py --require-lock` | Correcta: YAML/JSON, imports locales, enlaces, versión UI, SBOM y lockfile |
| Sintaxis de herramientas Python | `python3 -m compileall -q tool` | Correcta |
| JSON, SVG y conteo de casos | parser estándar + verificador de contrato | Correctos; 77 casos Dart/Flutter declarados |

No se ejecutó un validador de metaschema Draft 2020-12 independiente; el
verificador offline sí comprueba el dialecto, los 26 ids, las referencias de
fixtures y las restricciones de redacción específicas del contrato.

## Pruebas presentes, todavía no ejecutadas aquí

El repositorio declara 77 casos Dart/Flutter entre pruebas unitarias, widgets e
integración. Diecinueve cubren específicamente el contrato nuevo o sus fronteras:

- motor QR: HTTPS neutro, huella exacta, HTTP, Punycode, `userinfo`, esquema
  ejecutable, control codificado en `mailto:`, URL anidada, APK, IPv4 privada,
  excepción de dominio `fc*`, pagos y política de marca;
- evidencia: omisión completa de carga/URL, alteración, inclusión explícita,
  reordenamiento de claves y validación del enlace anterior;
- importación no confiable: recalcula id, hallazgos y decisión en vez de aceptar
  campos derivados del respaldo;
- privacidad: una URL con token se clasifica como sensible antes de decidir su
  persistencia.

Flutter y Dart no están instalados en el entorno de ensamblado actual. Por eso
no se afirma que `flutter analyze`, `flutter test` o un build de 0.1.0 hayan
pasado localmente. La CI incluida ejecuta esos pasos cuando el repositorio se
publique o se abra como proyecto Git.

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

## Gate requerido antes de un release binario

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

Después deben probarse en dispositivo físico la cámara, ciclo de vida, poca luz,
biometría, almacenamiento seguro y apertura externa. Para iOS/macOS se requiere
además entorno Apple; para distribución, firma y cuentas de tienda.

## Criterio de honestidad

Una validación estructural demuestra coherencia documental y de archivos. No
demuestra comportamiento en runtime. Una prueba Flutter demuestra el caso
codificado. Ninguna de las dos demuestra que un destino escaneado sea seguro.
