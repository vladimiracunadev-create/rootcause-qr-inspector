# Changelog

Todas las versiones notables se documentan aquí. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[Versionado Semántico](https://semver.org/lang/es/).

## [No publicado]

- Carga de políticas organizacionales desde la interfaz.
- Skeleton Unicode UTS #39 y Public Suffix List.
- Correlación opcional con otras superficies RootCause.
- Evidencia en dispositivo físico de la corrección de lectura de 0.1.1.

## [0.1.1] — 2026-08-26

Corrección de interacción de la cámara a partir de un reporte de uso real: una
lectura conseguida no se distinguía de que no ocurriera nada, y un código
legible pero lejano no se leía.

### Corregido

- **La lectura vuelve a funcionar sobre el mismo código.** El controlador usaba
  `DetectionSpeed.noDuplicates`, que emite un valor una sola vez y nunca más
  hasta que aparece otro código distinto; como el controlador sobrevive a
  parar y arrancar la cámara, volver a apuntar al mismo QR después de cerrar su
  resultado no producía ningún evento. El filtro de repetición pasa a la
  pantalla, dura 2,5 s desde que el código deja de verse y se explica en la
  barra de estado en vez de guardar silencio.
- **El marco deja de descartar códigos en silencio.** Se entregaba como
  `scanWindow` al motor, que rechazaba todo código cuyo recuadro cayera fuera
  del cuadrado central aunque la persona lo viera completo en pantalla. La
  detección cubre ahora toda la vista previa; el marco solo encuadra.
- **Los códigos lejanos entran en el rango del decodificador.** La resolución de
  captura no se declaraba y Android caía a 640×480. Se piden 1920×1080 en la
  pantalla de inspección y 1280×720 en el inventario.
- **Una captura se anuncia como captura.** Nuevo estado `Código leído`, con
  barra llena, marco fijo y botón propio. Antes, una lectura conseguida se
  anunciaba con el texto del estado `paused`: «Inspección en pausa».
- **La confirmación llega a tiempo.** El tono se precalienta al abrir la
  pantalla y ya no se espera antes de mostrar el resultado; la vibración de
  confirmación sube a `heavyImpact`.
- **El inventario cuenta unidades repetidas.** `noDuplicates` impedía sumar dos
  cajas idénticas seguidas: diez cajas contaban una. Cada unidad sumada se
  confirma además en la barra de estado.

### Cambiado

- El ajuste «Marco de lectura real» pasa a llamarse **«Marco de encuadre»** y su
  descripción declara que la lectura analiza toda la imagen. La clave de
  preferencia no cambia, así que las instalaciones existentes conservan su
  elección.

### Documentación

- `docs/quality/SCANNER_UX.md` incorpora los cinco estados de la cámara y una
  sección con la causa técnica de cada fallo corregido.
- La matriz de dispositivos añade las cuatro filas obligatorias de la
  corrección y declara que ninguna tiene todavía registro.

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

[0.1.1]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.1
[0.1.0]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.0
