# Contrato de compatibilidad

Compromisos heredados de Universal Code Scanner 1.0.0 y adoptados por RootCause
QR Inspector 0.1.1. Cada punto restringe cambios futuros para no romper datos o
instalaciones existentes.

## Datos del usuario

1. Ningún cambio de esquema elimina el origen antes de verificar la cantidad
   migrada y conservar un respaldo.
2. Cada cambio de esquema es idempotente y se aplica dentro de una transacción.
3. Los sobres cifrados declaran versión, algoritmo e identificador de llave; los
   sobres sin campo `version` se siguen aceptando como formato inicial.
4. Una llave ausente no se recrea durante el descifrado y no puede sobrescribirse
   de forma accidental.
5. La llave activa se guarda en metadatos transaccionales de la base de datos.
6. Los respaldos de Universal Code Scanner con `schemaVersion` 2 seguirán siendo
   importables, pero sus campos derivados se recalculan como entrada no
   confiable.
7. Una importación se valida por completo antes de combinar, omitir duplicados o
   reemplazar.
8. El modo temporal no abre la base persistente y no altera los datos del
   usuario.

## Extensiones

9. Los parsers nuevos se registran por `ContentParserRegistry` y no modifican el
   parser integrado.
10. Los motores nuevos se conectan mediante `ScannerEngine`; `MobileScannerEngine`
    sigue siendo el predeterminado.
11. Las capacidades futuras permanecen apagadas en `FeatureFlags`, y activar una
    bandera nunca cambia el formato persistente.

## Operación

12. La interfaz nunca confirma una mutación antes de que la base haya terminado
    de persistirla.
13. Las escrituras concurrentes de inventario se ejecutan en una cola serial.
14. Las dependencias se actualizan de forma individual, con pruebas de regresión
    y posibilidad de reversión.

## Contratos RootCause añadidos

15. Los ids de hallazgo son neutrales al idioma y solo cambian con migración
    documentada.
16. Hallazgos, hipótesis y decisión permanecen como campos distintos.
17. Cambiar condición o peso de una regla incrementa `engineVersion`.
18. Un resultado normal conserva la frase que niega una garantía de seguridad.
19. `rootcause.evidence.qr.v1` omite carga, parseo y URL efectiva por defecto.
20. El checksum de evidencia nunca se describe como firma o prueba de autoría.
21. Cambiar el significado de una preferencia conserva su clave y no reinterpreta
    la elección existente hacia un valor más permisivo. En 0.1.1, `use_scan_window`
    pasó de filtrar la detección a dibujar la guía de encuadre; quien lo tenía
    apagado sigue sin ver el marco.
22. La lectura nunca descarta un código en silencio: si se ignora por repetición,
    la interfaz lo dice.
