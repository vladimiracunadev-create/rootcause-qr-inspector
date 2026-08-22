# Changelog

Todas las versiones notables se documentan aquí. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[Versionado Semántico](https://semver.org/lang/es/).

## [No publicado]

- Carga de políticas organizacionales desde la interfaz.
- Skeleton Unicode UTS #39 y Public Suffix List.
- Correlación opcional con otras superficies RootCause.

## [0.1.0] — 2026-08-21

Primera derivación RootCause sobre Universal Code Scanner 1.1.0+2.

### Añadido

- contrato `rootcause.qr-investigation.v1` con 26 reglas locales, ids estables,
  severidad, puntos, confianza, hechos de evidencia y límites explícitos;
- seis hipótesis separadas, incluidas posible suplantación QR, robo de
  credenciales, entrega de software y sustitución de pago;
- política de acción `allow/confirm/inspectOnly/block` sin emitir el veredicto
  “seguro”;
- detección de autoridad engañosa, separadores codificados, redirección anidada,
  token de marca fuera de dominio, descargas sensibles y otras señales QR;
- vista de resultado con puntaje, ids, hechos e hipótesis;
- export `rootcause.evidence.qr.v1`, JSON Schema Draft 2020-12, SHA-256,
  redacción por defecto y enlace opcional a un paquete anterior;
- política organizacional de ejemplo y 12 fixtures sintéticos;
- documentación de arquitectura, heurísticas, integración, límites, referencias
  y procedencia;
- verificador offline del contrato y casos Flutter para motor, evidencia e
  importación no confiable.

### Seguridad

- el export redactado elimina también `effectiveUri`, que podría reconstruir
  consultas o secretos aunque `rawPayload` estuviera ausente;
- el checksum del paquete usa serialización determinista por claves y declara
  que no autentica autoría (`checksum-only-not-authenticated`);
- los respaldos importados no pueden imponer ids, puntajes o decisiones:
  RootCause los recalcula desde la observación;
- los nuevos registros serializan `scannedAt` en UTC para conservar ids y
  correlación al mover un respaldo entre zonas horarias;
- las URLs con claves de token, secreto, credencial o firma se tratan como
  sensibles y quedan fuera del historial automático;
- la huella de carga cubre el valor exacto, sin perder espacios o controles por
  normalización.

### Heredado

- captura, parsers, cifrado, historial, inventario, recuperación, generador,
  PWA y automatización de plataformas de Universal Code Scanner.

La procedencia exacta y las diferencias están en
[`docs/rootcause/PROVENANCE.md`](docs/rootcause/PROVENANCE.md).

[0.1.0]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.0
