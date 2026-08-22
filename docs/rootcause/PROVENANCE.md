# Procedencia y reutilización

## Base exacta

El repositorio se creó a partir de:

- repositorio: `vladimiracunadev-create/universal-code-scanner`;
- rama: `main`;
- commit: `c1f98781575bf8223b19ad8344fdfddeaccef373`;
- versión declarada: `1.1.0+2`;
- licencia: MIT;
- fecha de extracción: 20 de agosto de 2026.

## Componentes conservados

- arquitectura Flutter por capas;
- `ScannerEngine` y `MobileScannerEngine`;
- parser y registro extensible;
- modelos de contenido y formatos;
- importación de cámara, imágenes y PDF;
- historial e inventario;
- AES-256-GCM y almacenamiento seguro de llave;
- migraciones, recuperación y modo temporal;
- biometría, accesibilidad y ajustes;
- exportación y generador;
- scripts de bootstrap, SBOM y validación;
- pruebas y recursos de regresión.

## Componentes RootCause añadidos

- `QrInvestigation`, `QrFinding` y evidencia tipada;
- `QrInvestigationEngine` con 26 ids;
- `QrAnalysisPolicy` y `QrTrustedBrand`;
- separación hallazgo/hipótesis;
- `QrActionDecision`;
- `QrEvidenceExporter` y esquema JSON;
- UI de puntaje, ids, hechos e hipótesis;
- export de evidencia redactado por defecto;
- serialización determinista del checksum no autenticado del paquete;
- reanálisis de ids y veredictos importados no confiables;
- fixtures, pruebas y verificador de contrato;
- documentación de integración y límites.

## Compatibilidad de datos

Los exports de Universal Code Scanner continúan aceptándose. Todo registro que
entra por importación se reanaliza con el motor actual, incluso si declara una
investigación, porque el archivo no es una frontera confiable. El objeto
resultante conserva su `engineVersion`; no se reescribe la historia como si el
motor anterior hubiera producido esos ids.

## Identidad

La nueva aplicación usa:

- paquete Dart: `rootcause_qr_inspector`;
- nombre: `RootCause QR Inspector`;
- base de datos: `rootcause_qr_inspector_v2.db`;
- prefijo de llave: `rcqr_database_key_`;
- repositorio propuesto: `rootcause-qr-inspector`.

Puede instalarse y evolucionar como producto distinto sin apropiarse del
espacio de almacenamiento del lector original.

## Referencias de arquitectura RootCause

También se inspeccionaron, únicamente como referencia de diseño y contrato:

- `rootcause-mobile-inspector` —
  `8009c5f64e4147c51eceb6fbd87961a4f3e1229a`;
- `rootcause-web-inspector` —
  `681cbba2a788b45c152529acfbcbfe483a64a109`;
- `rootcause-windows-inspector` —
  `df30f98041f67be1c9e27ed665d90b2d9cef39b8`.

No se copió código desde esos tres repositorios. Se adoptaron patrones de
producto por superficie, ids estables, separación de evidencia e hipótesis y
límites explícitos. Ver [`ADOPTION_MATRIX.md`](ADOPTION_MATRIX.md).
