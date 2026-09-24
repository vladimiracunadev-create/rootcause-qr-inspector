# Fixtures de inspección de archivos

Datos exclusivamente sintéticos. Ningún dominio es un destino operativo:
`normal.example`, `trusted.example` y `evil.example` usan el TLD reservado
`.example`.

Archivos:

- `fixture_single_url.png`: un QR web;
- `fixture_multiple_codes.png`: URL, correo y Wi-Fi en una misma imagen;
- `fixture_no_code.png`: control negativo;
- `fixture_document.pdf`: cinco páginas, con QR en 1, 3 y 5 y un Code 128
  compacto en la página 2.

`manifest.json` es la expectativa legible por pruebas. Para regenerarlos:

```bash
python -m pip install qrcode pillow reportlab
python tool/generate_file_inspection_fixtures.py
```

El 7 de septiembre de 2026 se verificó el PDF con `pdfinfo`, se renderizaron
las cinco páginas con Poppler y se revisaron visualmente. El análisis, las
pruebas y el APK release están verdes; la decodificación con el motor nativo
continúa pendiente en un dispositivo Android compatible y no debe inferirse de
la inspección visual.
