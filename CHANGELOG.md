# Changelog

Todas las versiones notables se documentan aquí. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa
[Versionado Semántico](https://semver.org/lang/es/).

## [No publicado]

### Planificado

- Carga de políticas organizacionales desde la interfaz.
- Correlación opcional con otras superficies RootCause.
- Evidencia en dispositivo físico de la corrección de lectura de 0.1.1 y del
  gesto de zona de lectura de 0.2.0.
- `mobile_scanner 7.5.0` y `pdfrx 2.12.0`, en una ventana con prueba física
  (ver [política de dependencias](docs/quality/DEPENDENCY_POLICY.md)).

## [0.2.0] — 2026-11-06

Esta entrega hace dos cosas distintas: pone la zona de lectura en manos de la
persona con el gesto que el teléfono ya usa para eso, y le da al motor los
datos que le faltaban para afirmar que un dominio es quien dice ser.

### Añadido

- **La zona de lectura se maximiza y se minimiza pellizcando** sobre la vista
  previa. Al separar los dedos el encuadre crece y, pasado el 85 % de amplitud,
  el encabezado se retira y la cámara ocupa toda la pestaña; al juntarlos vuelve
  el encuadre pequeño. El gesto exige dos dedos, así que el toque de enfoque y
  el deslizador de zoom conservan el suyo.
- **Un indicador declara el porcentaje** mientras dura el ajuste y avisa cuándo
  se alcanza el máximo. Aparece con el gesto y se va solo: es información de la
  tarea, no un control fijo que reste imagen a la cámara. La primera vez que
  arranca la cámara nombra el gesto, porque una función que solo existe como
  gesto no se descubre.
- **El Inventario usa el mismo gesto y la misma preferencia.** Su visor estaba
  fijo en 230 px de alto: ahora crece hasta el 58 % de la pantalla y le cede
  altura a la lista de unidades. Su marco, además, deja de quedar debajo de la
  barra de estado.
- La amplitud elegida se recuerda entre sesiones y tiene un **control
  equivalente en Ajustes → Inspección QR**, operable con lector de pantalla
  para quien no pueda usar el gesto.
- A pantalla completa, la entrada por imagen o PDF se traslada a la esquina
  superior derecha del visor en lugar de desaparecer con el encabezado.
- **Aviso cuando la lectura no progresa:** a los 7 segundos analizando sin leer
  nada, el estado sugiere acercarse; a los 16, ofrece analizar una fotografía
  ya tomada. El motor no mueve el zoom por su cuenta: quitarle el encuadre a
  quien está apuntando es quitarle lo único que controlaba.
- **Regla 27, `host-whole-script-confusable`:** un host escrito entero en otra
  escritura cuyo esqueleto UTS #39 es ASCII puro. `host-mixed-script` solo veía
  la *mezcla*; un dominio en cirílico que se lee como una marca latina no mezcla
  nada y hasta ahora solo producía `host-unicode`, de confianza baja.
- **Regla 28, `host-embedded-suffix`:** un dominio de primer nivel escrito como
  etiqueta intermedia —`pago.com.atacante.example`—, donde no manda nada. No se
  disparan los ccTLD de dos letras: `es.`, `de.` y `cl.` son subdominios de
  idioma o región normales, y tratarlos como suplantación convertiría el
  hallazgo en ruido.
- **Public Suffix List completa** (6948 reglas ICANN y 3458 privadas, versión
  2026-11-04) y **tabla de confusables de UTS #39** (Unicode 18.0.0), generadas
  desde los archivos originales por `tool/generate_identity_data.py` con
  procedencia, fecha y SHA-256 dentro del archivo generado. La CI comprueba que
  sigan correspondiendo a sus fuentes. Alcance y envejecimiento declarados en
  [`docs/rootcause/IDENTITY_DATA.md`](docs/rootcause/IDENTITY_DATA.md).
- **El dominio registrable es evidencia visible** en `host-deep-subdomains` y
  `host-embedded-suffix`: es el dato que contesta la pregunta que el hallazgo
  plantea.
- `test/core/qr_fixtures_test.dart` **ejecuta los 16 fixtures** del banco de
  regresión contra el motor. Cierra R-01 del registro de riesgos.
- Gate de formato en CI (`dart format --set-exit-if-changed`) y
  [política de dependencias](docs/quality/DEPENDENCY_POLICY.md) escrita.
- La suite ejecutable pasa de 107 a 163 casos.

### Corregido

- **Un host Unicode se analizaba percent-codificado.** `Uri` entrega
  `%d1%80%d0%b0…`, puro ASCII, así que `host-unicode` y `host-mixed-script` no
  se disparaban nunca con un host escrito en otro alfabeto —justo el caso que
  dicen cubrir— y la evidencia mostraba a la persona una cadena de porcentajes
  en lugar del nombre que tiene delante. Un QR con dominio cirílico salía como
  `normal`, sin un solo hallazgo.
- **El catálogo de rutas señuelo no tenía `acceso`**, solo `access`, en un
  producto que se usa en español. Lo delató el primer fixture ejecutado:
  `userinfo-host-confusion` declaraba `credential-lure-path` desde 0.1.0 y el
  motor no lo producía. Se añaden `acceso`, `ingreso`, `ingresar`,
  `contraseña`, `desbloquear`, `restablecer` y `verificar`.
- **`redirect-nested-domain` comparaba familias de host por texto:** un host era
  familia de otro si uno terminaba en el otro, así que `ejemplo.com` y
  `ejemplo.com.atacante.example` pasaban por parientes. Ahora compara dominios
  registrables.
- **`brand-domain-mismatch` se esquivaba cambiando de escritura.** Ahora compara
  el token con el esqueleto del host.
- El marco del visor del Inventario quedaba parcialmente debajo de su propia
  barra de estado.
- Dos archivos llevaban tiempo sin formatear en el repositorio porque la CI no
  comprobaba el formato.
- **La CI ya no podía compilar Android y nadie lo sabía.** El runner de GitHub
  pasó a un JDK 25 en las seis semanas sin pushes, y Gradle 8.14.3 con AGP
  8.11.1 no lo soportan: `flutter build apk --release` fallaba con un mensaje
  que era solo la versión, `25.0.5`. La versión de Java era la única pieza de la
  cadena sin fijar, teniendo fijadas Flutter, Gradle, AGP y Kotlin. Los dos
  workflows fijan ahora Temurin 21. No lo provocó esta entrega: cualquier push
  de hoy habría fallado igual, y el build local seguía pasando porque esta
  máquina tiene otro JDK.
- **El gesto se podía maximizar de un pellizco, pero no minimizar de un
  pellizco.** La escala de un pellizco es multiplicativa —el cociente entre la
  distancia actual y la inicial— y se estaba tratando como lineal: separar los
  dedos multiplica sin techo, pero juntarlos nunca baja de cero, así que volver
  del máximo al mínimo exigía varios intentos. El recorrido pasa a ser
  logarítmico y simétrico: cuadruplicar la distancia recorre el rango hacia
  arriba y reducirla a la cuarta parte lo recorre hacia abajo. Lo encontró el
  pellizco real ejecutado en el emulador, no una revisión de código.

### Cambiado

- `QrInvestigationEngine.engineVersion` sube a `0.2.0`. Es obligatorio: sin
  ella, una evidencia exportada antes y otra después se declararían comparables
  sin serlo.
- Dependencias al día dentro del SDK fijado: `crypto 3.0.8`,
  `flutter_secure_storage 11.2.0`, `image_picker 1.2.4`, `sembast 3.10.0`,
  `sembast_web 2.4.6+1`, `share_plus 13.3.1`, `shared_preferences 2.5.6` y
  `url_launcher 6.3.3`. Quedan fuera con motivo escrito `mobile_scanner`,
  `pdfrx`, `cross_file`, `cupertino_icons`, `file_picker` y `web`.
- El análisis de archivos en navegador deja de anunciarse como **planificado**:
  es una decisión declarada, no una tarea atrasada. El botón lo dice
  —«en el navegador no hay decodificación local, usa el APK de Android»— y
  [`LIMITATIONS.md`](docs/rootcause/LIMITATIONS.md) explica por qué las dos vías
  disponibles no se incorporan.

### Verificado

- `dart format --output=none --set-exit-if-changed lib test tool`: sin cambios.
- `flutter analyze --fatal-infos`: sin issues.
- `flutter test`: 163 pruebas aprobadas.
- `python tool/verify_rootcause_contract.py`: 28 reglas coherentes entre motor,
  esquema, textos, fixtures, política, versión y redacción.
- `python tool/validate_structure.py --require-lock` y
  `python tool/generate_identity_data.py --check`: correctos.
- `flutter build apk --release` y `flutter build web --release`: correctos.
- Emulador Android API 36: `integration_test/reading_area_gesture_test.dart`
  separa y junta dos punteros reales sobre la vista previa; el encabezado se
  retira al máximo, el indicador declara `100 % · máxima` y al juntar los dedos
  vuelve a `50 %` con el encabezado a la vista. Exige conceder la cámara antes
  (`adb shell pm grant … android.permission.CAMERA`), por R-20.

### Pendiente, declarado

- El gesto no se ha probado en un teléfono real: no hay evidencia de que no
  compita con el toque de enfoque en hardware, ni de que el porcentaje se lea a
  pleno sol.
- Firma comercial de tienda, Play Store, App Store, iOS y la matriz física
  completa siguen pendientes, como en 0.1.4.
- Las tablas de identidad envejecen. La fecha de cada copia está en la cabecera
  del archivo generado; un sufijo creado después no se reconoce y el motor se
  queda corto, nunca inventa.

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
[0.2.0]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.2.0
[0.1.4]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.4
[0.1.3]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.3
[0.1.1]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.1
[0.1.0]: https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.0
