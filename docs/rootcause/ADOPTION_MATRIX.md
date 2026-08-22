# Matriz de adopción

Este documento responde qué se tomó de Universal Code Scanner, qué se
transformó para RootCause y qué se dejó fuera deliberadamente.

## Del lector universal al sensor QR

| Capacidad de origen | Decisión | Resultado en RootCause QR Inspector |
|---|---|---|
| Cámara, foco, zoom, linterna y ciclo de vida | Conservar | Sigue siendo el sensor primario de captura |
| Imágenes y PDF por lotes | Conservar | Permite investigar material recibido sin apuntar otra cámara |
| Soporte QR, 2D y 1D | Conservar | El producto se orienta a QR, pero no pierde la superficie de códigos existente |
| Parser de formatos estructurados | Conservar y conectar | `ParsedContent` entra al motor para distinguir OTP, pagos, binario y acciones |
| Analizador local de URL de 16 señales | Sustituir con compatibilidad | Motor de 26 reglas, ids estables y `RiskLevel` como adaptador heredado |
| Confirmación antes de abrir | Conservar y formalizar | Decisión tipada `allow/confirm/inspectOnly/block` |
| Historial e inventario AES-256-GCM | Conservar | La investigación completa se persiste dentro del registro cifrado |
| Keychain/Keystore, biometría y modo temporal | Conservar | Mantiene la frontera local de privacidad y recuperación |
| Export JSON/CSV/XLSX | Conservar | Sigue disponible para historial e inventario |
| Export de evidencia diagnóstica | Añadir | Contrato separado, redactado y con integridad SHA-256 |
| Generador de códigos | Conservar | Útil para pruebas, operaciones e inventario; no participa del veredicto |
| Scripts de bootstrap, lockfile, SBOM y CI | Conservar y extender | Añade verificación del contrato RootCause |
| Afirmaciones de release 1.1.0 | No transferir | Se guardan como procedencia, no como validación de 0.1.0 |

## Patrones adoptados de la familia RootCause

| Patrón | Aplicación QR |
|---|---|
| Producto por superficie observable | Nombre `RootCause QR Inspector`; phishing queda como hipótesis |
| Motor de reglas puro | `QrInvestigationEngine` no depende de Flutter, red o almacenamiento |
| Id neutral al idioma | El JSON conserva ids; la UI resuelve texto español por separado |
| Hecho antes que interpretación | `QrFinding.evidence` sustenta hipótesis sin convertirlas en certeza |
| Severidad explícita | `normal`, `warning`, `critical`; no se deduce del porcentaje |
| Evidencia portable | Esquema versionado, huella de carga, checksum no autenticado y límites |
| Limitaciones en la salida | Toda investigación declara capacidades ausentes |
| Diagnóstico antes de intervención | La vista explica y solo después presenta una acción |
| Compatibilidad sin confiar entradas | Los respaldos se aceptan, pero sus campos derivados se recalculan |

## Decisiones deliberadamente no tomadas

- no se incorporó una lista global de bancos o marcas reales;
- no se añadió reputación remota encubierta bajo “telemetría”;
- no se bloquea una URL solo por tener un hallazgo crítico si sigue siendo
  interpretable; se exige confirmación y evidencia visible;
- no se llama “cadena forense” a un hash anterior que todavía debe enlazarse de
  forma externa;
- no se afirma conformidad completa con Unicode UTS #39 ni cálculo normativo de
  eTLD+1;
- no se heredaron resultados de build o pruebas como si correspondieran al
  código derivado.

## Referencias de diseño inspeccionadas

- Universal Code Scanner —
  `c1f98781575bf8223b19ad8344fdfddeaccef373`;
- RootCause Mobile Inspector —
  `8009c5f64e4147c51eceb6fbd87961a4f3e1229a`;
- RootCause Web Inspector —
  `681cbba2a788b45c152529acfbcbfe483a64a109`;
- RootCause Windows Inspector —
  `df30f98041f67be1c9e27ed665d90b2d9cef39b8`.

El código derivado proviene de Universal Code Scanner. Los otros tres
repositorios se usaron como referencia de contrato y lenguaje de producto; no
se copió su código en esta entrega.
