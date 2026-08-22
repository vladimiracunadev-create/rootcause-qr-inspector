# Prompt maestro — RootCause QR Inspector

## Misión

Evoluciona `rootcause-qr-inspector` como un sensor forense local de la
superficie QR/código. Conserva lo mejor de Universal Code Scanner y aplica la
filosofía RootCause: observar, explicar, correlacionar y preservar evidencia;
diagnóstico primero, intervención después.

## Identidad que no debe romperse

- Producto: `RootCause QR Inspector`.
- Repositorio: `rootcause-qr-inspector`.
- Paquete Dart: `rootcause_qr_inspector`.
- Superficie: carga decodificada desde QR, 2D o código lineal.
- `qr-phishing-suspected` es una hipótesis, no el nombre del producto.
- No vender el producto como antivirus, EDR, reputación web ni garantía.
- No declarar “seguro”; decir “sin señales locales observadas”.
- Cero cuentas, publicidad, analítica y telemetría.
- Análisis local por defecto.

## Base que debe preservarse

Mantén funcionales:

1. cámara con estados visibles;
2. importación de imágenes y PDF por lotes con límites y cancelación;
3. formatos 2D/1D y parser estructurado;
4. historial/inventario cifrado AES-256-GCM;
5. Keychain/Keystore, biometría, sesión privada y recuperación;
6. generador y exportaciones;
7. Android, iOS, macOS y PWA;
8. accesibilidad, reducción de movimiento y diseño de ancho móvil;
9. scripts reproducibles, lockfile, SBOM y CI;
10. compatibilidad de importación con Universal Code Scanner.

## Contrato RootCause obligatorio

Cada análisis produce:

```text
QrInvestigation
  engineVersion
  analyzedAt
  payloadSha256
  verdict: severity + score + action
  normalizedHost?
  effectiveUri?
  findings[]
  hypotheses[]
  evaluatedRuleIds[]
  limitations[]
```

Cada `QrFinding` contiene id estable, severidad, puntos, confianza, categoría y
evidencia. El texto humano vive fuera del contrato.

## Reglas de honestidad

1. Hallazgo observable ≠ hipótesis ≠ veredicto.
2. Coincidencia temporal ≠ causalidad.
3. Regla no evaluable → omitida y límite declarado.
4. Puntaje ≠ probabilidad.
5. Host parseado ≠ sitio legítimo.
6. HTTPS ≠ sitio confiable.
7. Ausencia de reputación ≠ reputación favorable.
8. Política de marca vacía ≠ marca validada.
9. Datos sintetizados en tests usan `.example`, nunca dominios de phishing
   activos.
10. No abrir contenido automáticamente.

## Seguridad y privacidad

- Carga cruda, campos interpretados y `effectiveUri` omitidos de evidencia por
  defecto.
- OTP, Wi-Fi con contraseña, identidad y pagos tratados como sensibles.
- Nada sensible en logs, diagnósticos, nombres de archivo o telemetría.
- Export completo solo tras una decisión explícita y advertencia.
- `bundleHash` es checksum no autenticado; no llamarlo firma, sello ni prueba de
  autoría sin una capa criptográfica externa.
- Llaves fuera de la base y protegidas por el almacén de plataforma.
- Migraciones transaccionales, idempotentes y con recuperación.
- Id y análisis derivados de todo respaldo importado se recalculan; nunca se
  confían desde la entrada.
- No añadir proveedor remoto sin modo opt-in, política de privacidad, timeout,
  circuit breaker, redacción, cache y ruta offline equivalente.

## Arquitectura

- Dominio primero, UI como proyección.
- Motor Dart puro y determinista.
- Captura detrás de `ScannerEngine`.
- Parsers detrás de `ContentParserRegistry`.
- Política detrás de `QrAnalysisPolicy`.
- Evidencia conforme a `rootcause.evidence.qr.v1`.
- Dependencias fijadas; agregar una requiere justificar superficie, licencia y
  efecto por plataforma.

## Puerta para una nueva regla

No aceptes una regla sin:

- id neutral y estable;
- condición exacta y fuente de datos;
- severidad, peso y confianza;
- evidencia mínima no sensible;
- falso positivo documentado;
- test positivo;
- test negativo;
- fixture sintético;
- texto UI;
- actualización de `HEURISTICS.md`;
- incremento de `engineVersion` si cambia semántica.

## Correlación futura

Diseña para integrar:

- QR → Web por host, instante y descarga;
- QR → Mobile por app origen e instante;
- QR → Windows por destino y artefacto;
- todos → `rootcause-schema` por ids y hashes.

La integración 0.1.0 es export manual. No simules un bus o correlación que no
existe.

## Calidad mínima por cambio

Ejecuta:

```bash
python3 tool/validate_structure.py --require-lock
python3 tool/verify_rootcause_contract.py
flutter analyze --fatal-infos
flutter test
flutter build web --release
flutter build apk --release
```

En macOS agrega iOS `--no-codesign` y macOS release. Si una comprobación no se
puede ejecutar, declárala en `VALIDATION.md`; no la marques en verde.

## Entrega esperada

Una evolución está completa solo si código, tests, documentación, esquema,
fixtures, privacidad, versión, changelog y estado verificable cuentan la misma
historia. Todo lo no implementado debe decir `PLANIFICADO`, no insinuarse como
operativo.
