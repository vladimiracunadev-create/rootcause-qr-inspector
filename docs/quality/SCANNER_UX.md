# Comportamiento del escáner en cámara

## Analizar archivo sin degradar la cámara

La nueva acción textual vive en la fila ya existente del encabezado. Usa
`Analizar archivo` con ancho normal y se reduce a `Archivo` en menos de 430 px
o con escala de texto superior a 1,3; mantiene un objetivo táctil mínimo de
48×48. No añade una fila fija ni reduce la altura del visor. La cámara, zoom,
linterna, pausa, cambio y reinicio conservan sus controles y estados.

La hoja de fuente usa etiquetas accesibles: **Elegir imagen**, **Elegir varias
imágenes**, **Elegir PDF**. El progreso expone **Cancelar** y no transforma una
cancelación en persistencia parcial.

> Registro vivo de la interfaz de cámara de RootCause QR Inspector 0.1.1. La
> procedencia del subsistema heredado se conserva, pero los estados, controles
> y comprobaciones descritos aquí corresponden al producto RootCause actual.

Este documento explica **qué hace la pantalla de lectura en cada estado**, por
qué se eligió ese comportamiento y qué convenciones del sector se adoptaron.
Nace de una prueba en un teléfono real (agosto de 2026) en la que la cámara no
leía al abrir la aplicación y sí lo hacía al salir de la pestaña y volver.

---

## 1. El fallo que originó este trabajo

Reporte textual: *«el tema de lectura de código de barra no funciona; al salir y
volver se activa»*.

La pantalla mostraba la imagen de la cámara y un texto fijo —«Alinea uno o varios
códigos dentro del marco»— **idéntico tanto si el motor estaba analizando cuadros
como si no**. Ese texto era la única señal de estado, así que una cámara que no
llegaba a arrancar era visualmente indistinguible de una cámara esperando un
código. El usuario no tenía forma de saber cuál de las dos cosas ocurría, ni
manera de corregirlo sin abandonar la pestaña.

Tres causas técnicas concretas, las tres corregidas:

| Causa | Efecto observado | Corrección |
|---|---|---|
| `scanWindowUpdateThreshold: 4` congelaba la ventana de lectura | La ventana se calcula en **porcentajes** (0 a 1) sobre el tamaño de la cámara y la orientación del dispositivo, datos que pueden llegar después del primer cuadro. Un umbral de 4 sobre una magnitud que nunca varía más de 1 significaba «no recalcular nunca»: si la primera ventana salía mal, todo código quedaba fuera de la región analizada | Sin umbral: la ventana se recalcula cuando cambian el tamaño, la orientación o el diseño |
| El ciclo de vida de la aplicación quedaba sin atender | `MobileScanner` solo gestiona el ciclo de vida **cuando él crea el controlador**. Esta pantalla le pasa el suyo, así que volver del segundo plano —o del diálogo de permiso de cámara del sistema— dejaba la vista previa congelada | `ScannerScreen` e `InventoryScreen` observan el ciclo de vida y reinician la cámara al volver |
| Ningún error de arranque llegaba a la interfaz | `start()` puede lanzar excepción (controlador desechado, ya iniciándose, permiso denegado) y nadie la capturaba ni la mostraba | Todo arranque pasa por `_startCamera()`, que captura el fallo y lo convierte en un estado visible con acción de recuperación |

---

## 2. Los cinco estados, siempre visibles

La barra superior nombra el estado, lo describe y lo dibuja. Es una
`ScanStatusBar` con una **barra horizontal** que solo se mueve cuando el motor
está analizando cuadros de verdad.

| Estado | Título | Barra | Acción ofrecida |
|---|---|---|---|
| `starting` | «Preparando inspección…» | En movimiento | Botón desactivado «Preparando» |
| `scanning` | «Inspección activa» | En movimiento + línea que recorre el marco | Botón «Pausar» |
| `captured` | «Código leído» | Llena y quieta, marco fijo encendido | Botón desactivado «Leído»; se abre el análisis |
| `paused` | «Inspección en pausa» | Detenida y vacía | Botón «Reanudar»; el visor no es un control oculto |
| `unavailable` | «Sensor no disponible» | Detenida, en color de error | «Reintentar» (reconstruye el controlador) |

`captured` se añadió en 0.1.1. Hasta entonces una lectura conseguida se
anunciaba con el estado `paused` —«Inspección en pausa», «Lectura detenida»—,
es decir, con el vocabulario del estado contrario. Ver la sección 6.

El escaneo **sigue siendo automático**: no hay que pulsar nada para leer un
código, que es lo que hace cualquier lector del sector. Lo que se añadió es la
respuesta permanente a la pregunta «¿está escaneando ahora mismo?», más un botón
explícito para pausar y reanudar cuando el usuario quiere controlarlo. La barra
es compacta, usa una línea por texto con elipsis y reserva el área central para
el QR incluso en vistas de 288×320, 400×560 y 430×760.

Con **movimiento reducido** activado en Ajustes, la barra se dibuja llena y
quieta, y el marco no barre la línea: el estado sigue siendo legible sin
animación.

---

## 3. Confirmación sonora

Antes, la confirmación era `SystemSound.play(SystemSoundType.click)`, que en
Android se traduce al efecto de sonido de la interfaz: **silencioso en cuanto el
usuario apaga los sonidos táctiles del sistema**, que es el ajuste habitual. Por
eso «faltaba el sonido» aunque el código dijera que lo emitía.

Ahora suena un tono propio empaquetado en la aplicación:

- `assets/sounds/scan_success.wav`, generado por `tool/generate_scan_beep.py`
  (dos pulsos cortos y agudos, 2 000 Hz y 2 800 Hz, ~150 ms).
- Se reproduce con `audioplayers` en modo de baja latencia y con la fuente
  precargada, para que el pitido llegue junto con la lectura y no después.
- Desde 0.1.1 el reproductor se construye al abrir la pantalla
  (`ScanFeedback.warmUp`) y la reproducción **no bloquea** la apertura del
  resultado. Antes, la primera lectura pagaba la creación del reproductor, el
  contexto de audio y la carga del asset mientras la persona ya esperaba: el
  resultado llegaba tarde y la lectura parecía no haber ocurrido.
- La vibración de confirmación es `heavyImpact`: un toque suave pasaba
  inadvertido con el teléfono en la mano extendida.
- Se mezcla con el audio existente (`mixWithOthers`): no interrumpe música ni
  llamadas por un tono de una décima de segundo.
- `ScanFeedback` degrada al sonido del sistema si el reproductor falla, y deja de
  intentarlo. Ni el sonido ni la vibración pueden romper una lectura.
- Sonido y vibración siguen siendo dos ajustes independientes.

---

## 4. Convenciones del sector adoptadas

Comparación con lo que ofrecen los lectores de códigos de uso masivo —cámara
nativa de iOS y Android, Google Lens, y lectores libres como Binary Eye o
ZXing—, y estado en esta aplicación:

| Convención | Antes | Ahora |
|---|---|---|
| Lectura automática sin pulsar nada | Sí | Sí |
| Indicador visible de «escaneando» | No | **Barra en movimiento + línea que recorre el marco** |
| Botón explícito de activar/pausar | Icono sin etiqueta | **Botón con texto «Pausar» / «Reanudar»** |
| Pitido de lectura conseguida | Dependiente de los sonidos táctiles del sistema | **Tono propio empaquetado** |
| Vibración de confirmación | Sí | Sí |
| Recuperación cuando la cámara no arranca | No existía | **«Reintentar» y «Reiniciar cámara»** |
| Mensaje específico de permiso denegado | No | Sí |
| Reanudar tocando la vista previa | No | **No; se eliminó el gesto oculto** |
| Linterna | Sí | Sí |
| Enfoque al tocar | Sí | Sí |
| Zoom | Deslizador | Deslizador |
| Cambio de cámara | Sí | Sí |
| Lectura de varios códigos a la vez | Sí | Sí |
| Detección en toda la imagen | No: el marco filtraba | **Sí; el marco solo encuadra** |
| Confirmación visible de «leído» | No: reusaba «en pausa» | **Estado propio «Código leído»** |
| Volver a leer el mismo código | No hasta reiniciar | **Sí, apartando y volviendo a apuntar** |
| Resolución de captura | Por defecto de la plataforma | **1920×1080 pedidos en inspección** |
| Importar desde galería y PDF | Sí | Sí |
| Historial de lecturas | Sí | Sí |
| Modo continuo (inventario) | Sí | Sí, además con pausa y estado visible |

Diferencias deliberadas con el resto del sector: esta aplicación **no abre nada
sin confirmación** y **no envía nada a servidores**. El análisis de riesgo de la
URL y la interpretación del contenido ocurren antes de cualquier acción, y esa
decisión no se toca.

---

## 5. Qué se comprobó en RootCause QR Inspector

Comprobado en 0.1.0, sobre el APK público de esa versión:

| Comprobación | Resultado |
|---|---|
| `flutter analyze --fatal-infos` | 0 hallazgos |
| `flutter test --coverage` | 81 de 81 en verde |
| Geometría responsive | Marco sin solaparse con estado/controles en tres proporciones, desde 288×320 |
| Texto ampliado | Barra compacta sin overflow a 320×640 y escala 1,6 |
| `flutter build apk --release` | APK 0.1.0 generado por el mismo workflow verde |
| Emulador Android 36.1, 1080×2400 | Lectura automática → Pausar → Reanudar → lectura automática |

La jerarquía accesible del APK instalado confirmó `Lectura detenida` y
`Reanudar` durante la pausa, y `Lectura automática` y `Pausar` después de
reanudar. No contiene la antigua instrucción «toca la pantalla». La matriz de
teléfonos físicos continúa siendo necesaria antes de una publicación en tienda.

Estado de la comprobación en 0.1.1: [`../../VALIDATION.md`](../../VALIDATION.md).

---

## 6. El fallo de 0.1.0 corregido en 0.1.1

Reporte textual: *«no hay un sonido, cambio de pantalla o acción clara cuando se
escanea bien; y cuando el código está lejos y se puede leer igual porque se ve
completo y bien, parece que no hace nada»*.

Eran tres causas distintas que producían el mismo síntoma —silencio— y se
reforzaban entre sí:

| Causa | Efecto observado | Corrección |
|---|---|---|
| `DetectionSpeed.noDuplicates` en el controlador | El motor emite un valor **una sola vez y nunca más** hasta que aparece un código distinto. Como el controlador sobrevive a parar y arrancar la cámara, volver a apuntar al mismo QR después de cerrar su resultado no producía ningún evento: la aplicación parecía muerta | `DetectionSpeed.normal`. El filtro de repetición vive ahora en la pantalla, con una ventana de 2,5 s que se reinicia mientras el código siga a la vista, y **se explica**: «Ese código ya se inspeccionó; aparta y apunta otra vez» |
| `scanWindow` entregado al motor como filtro duro | El marco central descartaba en silencio todo código cuyo recuadro cayera fuera, incluido uno perfectamente legible en pantalla. El texto de estado además prometía «Lectura automática dentro del marco» | El marco es **guía de encuadre**, no filtro. La detección cubre toda la vista previa. El ajuste pasa a llamarse «Marco de encuadre» y su descripción lo declara |
| `cameraResolution` sin declarar | Android cae a **640×480**. Un QR a distancia ocupa muy pocos píxeles a esa resolución aunque la vista previa reescalada se vea nítida: la persona ve el código completo y el decodificador no lo alcanza | Se piden 1920×1080 en la pantalla de inspección y 1280×720 en el inventario, que analiza de forma continua |
| Confirmación de lectura tardía y ambigua | La reproducción del tono se esperaba **antes** de mostrar el resultado, y la primera lectura pagaba la construcción del reproductor. El estado visible pasaba a «Inspección en pausa», el vocabulario del estado contrario | Estado propio `captured` («Código leído», barra llena, marco fijo), tono precalentado al abrir la pantalla, reproducción no bloqueante y vibración `heavyImpact` |

Efecto lateral corregido en el inventario: `noDuplicates` impedía **contar dos
unidades iguales seguidas**. Diez cajas idénticas sumaban una. El filtro de
1200 ms de `_onDetect` es ahora el único que evita contar el mismo código en
cada cuadro, y cada unidad sumada se confirma en la barra de estado.

Lo que estas correcciones **no** demuestran: ninguna prueba automatizada puede
comprobar que un QR lejano se lee en un teléfono real. Las pruebas de
`test/features/scanner_engine_config_test.dart` solo impiden que la
configuración vuelva a los valores que causaron el reporte. La comprobación en
hardware sigue pendiente y está declarada como tal.

---

## 7. Maximizar y minimizar la zona de lectura

Reporte textual: *«dar la opción de maximizar o minimizar la zona de lectura del
código […] con el gesto por defecto de la pantalla táctil, no por un botón; y
que salga un porcentaje a modo de información de la tarea»*.

Antes de este cambio el encuadre era fijo: un cuadrado del 72 % del ancho de la
vista previa (64 % en pantallas cortas o estrechas), y el único ajuste
relacionado —«Marco de encuadre»— solo lo dibujaba o lo ocultaba. No había
forma de darle más imagen a la cámara.

### Qué hace el gesto

| Gesto | Efecto | Señal |
|---|---|---|
| Pellizcar separando dos dedos sobre la vista previa | La amplitud sube hasta 1; el marco crece | Indicador «Zona de lectura N %» |
| Cuadruplicar la distancia entre los dedos | Recorre el rango completo hacia arriba; reducirla a la cuarta parte lo recorre hacia abajo | — |
| Pasar del 85 % de amplitud | El encabezado y las insignias se retiran, la vista previa pierde margen y esquinas redondeadas y ocupa toda la pestaña | «Zona de lectura 100 % · máxima» |
| Pellizcar juntando los dedos | La amplitud baja; el encabezado vuelve | Indicador con el nuevo porcentaje |
| Levantar los dedos | La amplitud se guarda en preferencias | El indicador se desvanece a los 1,6 s |

La amplitud es **continua**, no un interruptor de dos posiciones, porque el
gesto lo es: un pellizco a medias debe dejar un encuadre a medias. El
porcentaje mostrado va de 50 % a 100 %; declarar 0 % en el extremo pequeño
diría «sin zona de lectura», que es justo lo que no ocurre —el encuadre mínimo
sigue cubriendo la mitad de la imagen—.

El recorrido es **logarítmico**, y esa decisión la impuso el dispositivo. La
primera versión restaba `scale - 1`: separar los dedos multiplica la distancia
sin techo, así que maximizar salía de un gesto; juntarlos, en cambio, nunca baja
de cero, de modo que la resta no podía bajar más de un punto y **volver del
máximo al mínimo exigía varios pellizcos**. El pellizco real en el emulador lo
destapó en su segundo paso: el encabezado no volvía. Con el logaritmo, ir y
volver cuestan el mismo gesto.

### Decisiones y por qué

| Decisión | Motivo |
|---|---|
| Pellizco de **dos dedos**, y el detector al fondo de la pila | Un dedo sobre la vista previa es el toque de enfoque de `MobileScanner`, y el deslizador de zoom y los botones están por encima del detector: ninguno pierde su gesto |
| El pellizco ajusta la **zona de lectura**, no el zoom de la cámara | Es lo pedido. El zoom conserva su deslizador propio, visible y etiquetado, así que no se pierde ninguna de las dos funciones. Queda anotado como riesgo de descubrimiento: en muchas aplicaciones de cámara el pellizco significa zoom |
| La pista «Pellizca para ampliar la zona» aparece una vez, al arrancar la cámara, en el mismo indicador | Una función que solo existe como gesto no se descubre. No va en la barra de estado porque su línea secundaria se recorta a un renglón: un texto más largo saldría con puntos suspensivos. La pista cede el sitio al porcentaje en cuanto empieza el gesto |
| Control equivalente en **Ajustes → Inspección QR** | Un gesto de dos dedos no es operable con lector de pantalla ni con control por conmutador. El deslizador de Ajustes expone el mismo valor y su porcentaje |
| El indicador **no** es un control | No acepta toques, así que no compite con la cámara ni introduce un objetivo táctil que tape imagen; aparece con el gesto y se va solo |
| La amplitud se **recuerda** | Quien inspecciona códigos pequeños o lejanos quiere el mismo encuadre en la lectura siguiente. Se guarda al terminar el gesto, no en cada cuadro |
| Pantalla completa a partir de 0,85 y no de 1 exacto | Un pellizco rara vez termina en el extremo justo; exigirlo convertiría «pantalla completa» en algo casi inalcanzable |
| A pantalla completa, «Analizar archivo» se traslada a la esquina superior derecha | El botón vivía en el encabezado, que ya no se dibuja. La barra de estado reserva ese hueco en lugar de quedar debajo del botón |

### Qué comprueban las pruebas y qué no

`test/features/scanner_viewport_geometry_test.dart` fija que el marco nunca
invade la barra de estado ni la banda de controles **en toda la amplitud** y en
cuatro tamaños de vista previa, que crecer el pellizco nunca encoge el marco,
que el umbral de pantalla completa es el declarado y que el porcentaje va de 50
a 100 incluso con una preferencia fuera de rango.

Lo que **no** demuestran: que el pellizco se sienta natural en un teléfono real,
que no compita con el toque de enfoque en hardware ni que el porcentaje se lea
sin esfuerzo a pleno sol. Eso exige la matriz física, que sigue pendiente y
declarada como tal.

### El mismo gesto en el Inventario

El inventario cuenta unidades en serie, así que su zona de lectura no es un
recuadro dentro de la cámara: **es el alto del visor**. Hasta 0.1.4 medía 230 px
fijos, con la lista de unidades debajo. Contar treinta cajas por esa franja era
la operación más incómoda del producto.

Ahora el mismo pellizco, con la misma preferencia, lleva el visor hasta el 58 %
de la pantalla y le cede alto a la lista. El techo no es un capricho: por debajo
del visor siguen la lista y la barra de navegación, y un visor que se las coma
deja la pantalla sin salida.

Dos diferencias deliberadas con el inspector:

| Inspector | Inventario |
|---|---|
| Al máximo retira el encabezado y ocupa la pestaña entera | Nunca ocupa la pestaña entera: la lista de unidades es parte de la tarea |
| Marco cuadrado, para QR | Marco **rectangular ancho**, y su alto nunca pasa del 62 % de su ancho: un inventario lee códigos de barras lineales |

Corregido de paso: el marco fijo se metía parcialmente debajo de la barra de
estado del propio visor. Ahora se centra en la banda que queda por encima de
ella.
