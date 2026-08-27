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
