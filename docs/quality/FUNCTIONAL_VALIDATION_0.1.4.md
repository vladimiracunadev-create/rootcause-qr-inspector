# Validación funcional 0.1.4

Fecha: 2026-09-24  
Entorno: Android Emulator `Medium_Phone_API_36.1`, Android API 36, APK release
`0.1.4` (`versionCode 5`)  
Fixture: `test_assets/file_inspection/fixture_document.pdf`, datos sintéticos

## Criterio de evidencia

Este informe no equipara compilación con funcionamiento. Cada comprobación se
clasifica como **interactiva**, **automatizada**, **build** o **no ejecutada**.

## Resultado black-box

| Flujo | Evidencia | Resultado observado | Estado |
|---|---|---|---|
| Inicio sin permiso de cámara | Interactiva | La aplicación siguió utilizable, explicó que faltaba el permiso y mantuvo disponible `Analizar archivo local` | Aprobado |
| Seleccionar PDF desde Descargas | Interactiva | El selector del sistema mostró y abrió `fixture_document.pdf` | Aprobado |
| Analizar PDF completo | Interactiva | Progreso visible de renderizado y análisis; 5 páginas inspeccionadas, 4 códigos, 4 únicos y 1 página sin código | Aprobado |
| Reconocer código de barras | Interactiva | La página 2 apareció como `Code 128`; el historial conservó la carga cruda `RCQR-1234567890` | Aprobado |
| Persistir resultados | Interactiva | Historial mostró 2 registros no sensibles; el URL crítico y la configuración Wi-Fi no se persistieron por política | Aprobado |
| Exportar Historial a navegador | Interactiva | La confirmación abrió la hoja de compartir con `casos-qr-inspeccionados.html` | Aprobado |
| Abrir enlace desde Historial | Interactiva | La app exigió confirmación y delegó la URL sintética a Chrome (`com.android.chrome`) | Aprobado en Android |
| Nueva pestaña en Web | Automatizada | La prueba verifica `_blank` para HTTP/HTTPS y `noopener noreferrer` en HTML | Aprobado automatizado |
| Exportación HTML de Inventario | Automatizada | Documento autocontenido, UTF-8, enlaces en pestaña nueva y contenido no confiable escapado | Aprobado automatizado |
| Sonido y vibración al validar archivo | Automatizada | `ScanFeedback` prueba tono, vibración, ajustes independientes y fallback del sistema; el lote llama una vez a esa ruta | Aprobado automatizado |
| Sonido audible en dispositivo físico | No ejecutada | El emulador no constituye evidencia de percepción acústica ni vibración física | Pendiente físico |

## Defecto encontrado durante la prueba

La primera ejecución real falló aunque el build y los tests unitarios pasaban.
El log de Android mostró que ML Kit intentaba abrir `page_2.png` después de que
la aplicación ya lo había eliminado (`FileNotFoundException`, `ENOENT`). El
flujo devolvía el `Future` de análisis desde un `try/finally` sin esperarlo, por
lo que la limpieza de temporales comenzaba antes de terminar la decodificación.

Se corrigieron ambos flujos de archivo para esperar explícitamente el análisis
antes de reiniciar la cámara o borrar páginas. El verificador de contrato ahora
falla si reaparece un `return FileInspectionCoordinator(...)` no esperado en
esas dos rutas. La prueba black-box completa se repitió con un APK nuevo.

## Evidencia visual

- [Resumen: 4 resultados en 5 páginas](evidence/v0.1.4/pdf-4-results.png)
- [Code 128 reconocido en la página 2](evidence/v0.1.4/pdf-code128-result.png)
- [Carga cruda conservada en Historial](evidence/v0.1.4/history-code128.png)
- [Archivo HTML presentado por Android](evidence/v0.1.4/history-html-share.png)

Las capturas contienen únicamente fixtures sintéticos del repositorio.

## Alcance pendiente

La prueba interactiva se ejecutó en emulador. Antes de afirmar certificación
física aún debe comprobarse cámara, vibración, audio audible y rendimiento con
PDF reales en al menos un teléfono Android compatible.
