# Changelog

Todas las versiones notables se documentan aquí. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[Versionado Semántico](https://semver.org/lang/es/).

## [No publicado]

### Planificado

- Carga de políticas organizacionales desde la interfaz.
- Skeleton Unicode UTS #39 y Public Suffix List.
- Correlación opcional con otras superficies RootCause.
- Evidencia en dispositivo físico de la corrección de lectura de 0.1.1.

## [0.1.4] — 2026-09-24

### Corregido

- Los PDF se rasterizan con una política adaptativa acotada a 4096 px para
  preservar barras estrechas y QR pequeños antes del análisis nativo.
- Las páginas temporales permanecen disponibles hasta que termina la
  decodificación nativa; antes podían borrarse mientras ML Kit abría la página
  siguiente.
- El banco sintético incluye ahora un Code 128 compacto dentro de un PDF, no
  sólo QR grandes, para proteger la regresión reportada.
- La validación correcta desde imagen o PDF confirma con el mismo tono y
  vibración configurables que la cámara y el inventario, una vez por lote.
- Los enlaces HTTP/HTTPS se entregan explícitamente al navegador y en web se
  abren en una pestaña nueva.

### Añadido

- Exportación HTML autocontenida de Historial e Inventario, legible directamente
  por navegador, con contenido escapado y enlaces en pestaña nueva protegidos
  mediante `noopener noreferrer`.
- Pruebas de resolución PDF, exportación HTML segura de Historial e Inventario
  y política de apertura de enlaces; la suite ejecutable pasa de 103 a 107 casos.

### Verificado

- Contrato RootCause, estructura, análisis estricto y 107 pruebas Flutter.
- APK 0.1.4 validado en emulador Android API 36: el PDF sintético produjo 4
  resultados en 5 páginas y reconoció el Code 128 de la página 2. Permanece
  pendiente la validación de audio, vibración y cámara en dispositivo físico.

## [0.1.3] — 2026-09-07

### Añadido

- Evolución de la importación existente a **Analizar archivo**, visible junto
  a la cámara y adaptable a pantallas estrechas y texto ampliado.
- Coordinación testeable de imágenes y páginas PDF mediante
  `FileInspectionCoordinator` y `FileCodeDecoder`, reutilizando
  `ScannerEngine` en nativo y sin crear un segundo scanner.
- Presentación semántica `ResolvedScanTarget`: explica qué se encontró, qué
  contiene, a qué apunta y destaca el host real antes de ofrecer una acción.
- Procedencia sin nombres ni rutas privadas (`Imagen · N`,
  `PDF · página N`), deduplicación por unidad, progreso con códigos hallados y
  mensajes explícitos cuando no fue posible detectar códigos.
- PDF con cabecera y tamaño validados, metadatos de páginas totales/inspeccionadas,
  límite visible de 50 páginas y limpieza/cancelación conservadas.
- Pruebas unitarias y widget para múltiples códigos, duplicados, unidades sin
  código, cancelación, procedencia, limpieza PDF, destino semántico, texto al
  200 % y ausencia de acción externa cuando el motor bloquea.
- Selector persistente de español (Chile e internacional), inglés, francés y
  alemán; navegación, acciones y ayuda principal cambian de idioma al instante.
- Guía rápida para las cinco pestañas desde Ajustes y ayuda contextual en
  Inventario, con un flujo de cuatro pasos que distingue códigos únicos de
  unidades físicas repetidas.
- Pruebas de localización y de la guía en pantalla de 320 px con texto al 160 %.

### Documentación

- Manual de Inventario ampliado, idiomas y nuevas pantallas documentados.
- Landing de GitHub Pages, metadatos del repositorio y enlaces de descarga
  actualizados para 0.1.3.

### Verificado

- Contrato y estructura offline, análisis estricto, suite Flutter completa,
  compilaciones web/APK y CI pública deben permanecer verdes para publicar el
  tag; la validación física de cámara sigue declarada como pendiente.

## [0.1.2] — 2026-08-31

Entrega de mejora del generador. El motor de investigación, las 26 reglas, el
contrato de evidencia y el tema visual no cambian.

### Añadido

- Descarga directa de los códigos generados como PNG o SVG en la demo web.
- Exportación adaptada por plataforma: descarga en navegador y hoja nativa de
  compartir en Android/iOS para guardar, enviar o abrir la imagen.
- Confirmación visible después de preparar cada archivo.

### Cambiado

- Las acciones distinguen entre **Copiar/Compartir contenido** y
  **Descargar/Compartir PNG o SVG**, para no confundir el texto codificado con
  la imagen del código.
- El generador explica que un código no caduca por sí solo; la disponibilidad
  depende del contenido o destino codificado.

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

[0.1.2]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.2
[0.1.4]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.4
[0.1.3]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.3
[0.1.1]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.1
[0.1.0]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.0
