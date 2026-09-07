# Rendimiento y memoria

- La cámara de inspección pide 1920×1080 y la de inventario 1280×720. El valor
  por defecto de Android —640×480— no alcanza para un código lejano; el
  inventario pide menos porque analiza de forma continua durante minutos. Ambos
  valores requieren medición en dispositivos reales de gama baja: memoria,
  tiempo y temperatura.
- Galería limitada a 20 imágenes por operación.
- PDF limitado a 50 páginas.
- Render PDF ajustado a un máximo aproximado de 2400 px en su lado mayor.
- Cada imagen PDF se libera y elimina después del análisis; la cancelación se propaga también al renderizador de página.
- Los procesos masivos muestran progreso y pueden cancelarse.
- El historial se limita a 5000 registros.
- Las operaciones de cifrado se preparan antes de la transacción para reducir bloqueos.
- Las rotaciones de llave y las escrituras de inventario se serializan para evitar carreras entre lecturas continuas, cambios de cantidad y notas.
- La interfaz se actualiza solo después de confirmar la persistencia segura.
- Los límites no deben ampliarse sin medir memoria, tiempo y temperatura en dispositivos reales.

## Inspección de archivos no confiables

- Constantes compartidas: 20 imágenes, 50 páginas PDF, 50 MiB por archivo y
  2400 px como lado rasterizado objetivo.
- Cada unidad se analiza secuencialmente; la deduplicación conserva una carga
  por imagen o página, no elimina ocurrencias legítimas de archivos distintos.
- El progreso informa unidad actual y códigos acumulados. La cancelación se
  comprueba antes y después de decodificar y evita devolver un lote parcial.
- PDF valida tamaño y cabecera `%PDF-` antes de abrirlo, libera objetos de
  imagen y elimina temporales en éxito, error y cancelación.
- **Pendiente:** medir tiempo, pico de memoria y temperatura con PDF de 50
  páginas e imágenes extremas en dispositivos de gama baja.
