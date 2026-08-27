# Accesibilidad e idiomas

## Idiomas en 0.1.1

La interfaz se entrega **solo en español**: idioma del sistema, español de Chile
(`es_CL`) y español internacional (`es`).

La infraestructura de localización admite inglés y `AppLocalizations` ya
contiene sus claves, pero el resto de las pantallas todavía usa literales en
español. Exponer `en` produciría una interfaz a medio traducir —barra de
navegación en inglés sobre contenido en español—, así que el delegado rechaza
ese idioma y Flutter recae en el primer idioma admitido. Una prueba verifica esa
decisión para que no se revierta por accidente.

El inglés se activará cuando todas las pantallas lean sus cadenas de
`AppLocalizations`. Las cadenas nuevas deben añadirse allí antes de incorporarse
a la interfaz.

## Opciones de accesibilidad

Opciones incluidas:

- alto contraste;
- controles táctiles más grandes;
- reducción de transiciones —con ella activada, la barra de estado del escáner
  se dibuja llena y quieta, y el marco no barre la línea de lectura: el estado
  sigue siendo legible sin movimiento;
- escala tipográfica del sistema sin limitar;
- etiquetas semánticas en acciones críticas;
- compatibilidad prevista con TalkBack, VoiceOver y teclado.

La matriz de dispositivos exige revisar contraste, orden de foco, nombres
accesibles y tamaño táctil.

Una prueba de widget levanta el Centro de recuperación con la escala tipográfica
al 200 % y comprueba las guías `labeledTapTargetGuideline` y
`textContrastGuideline` de Flutter.

La barra de estado del escáner se anuncia como región activa (`liveRegion`) con
el estado y la instrucción en una sola etiqueta, para que un lector de pantalla
comunique el cambio de «Inspección activa» a «Inspección en pausa» sin que la persona
tenga que buscarlo.

Desde 0.1.1 una captura tiene su propio anuncio, «Código leído», en vez de
compartir el de una cámara en pausa. Esto importa especialmente sin sonido ni
vibración: para quien lee la pantalla con un lector, ese texto era la única
diferencia entre «se leyó el código» y «la cámara se detuvo», y no existía. El
aviso de repetición usa el mismo canal, de modo que un código ignorado por ser
repetido también se anuncia.
