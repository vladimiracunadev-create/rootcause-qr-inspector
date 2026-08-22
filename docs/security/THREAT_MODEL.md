# Modelo de amenazas

## Activos

Historial, inventarios, contraseñas Wi-Fi, semillas OTP, información de pagos, identificaciones, llave local y archivos exportados.

## Límites de confianza

- cámara y galería;
- archivos JSON/PDF/imágenes importados;
- almacén seguro del sistema;
- base Sembast/IndexedDB;
- aplicaciones externas abiertas mediante URI;
- portapapeles;
- archivos compartidos.

## Amenazas y controles

| Amenaza | Control |
|---|---|
| QR dirige a phishing o ejecutable | 26 reglas locales, hechos e hipótesis separados, dominio visible, confirmación y bloqueo de URI ambiguas |
| Acción no web inyecta controles | controles crudos o porcentuales se detectan en toda URI accionable y eliminan la acción externa |
| Archivo importado impone un veredicto o id | límite de tamaño, esquema versionado, vista previa y recálculo obligatorio de todo campo derivado |
| Pérdida de llave | incidencias de recuperación, respaldo cifrado, no recrear la llave durante descifrado y no borrar registros automáticamente |
| Manipulación de la base | AES-GCM autentica cada carga y los errores se aíslan |
| Exposición en logs | diagnóstico acepta solo tipo, área y huella de stack |
| Exposición por portapapeles | confirmación previa para cargas sensibles y borrado programado |
| URL con token queda en historial ordinario | claves sensibles de consulta, fragmento o `userinfo` marcan el contenido y lo excluyen de persistencia automática |
| Export redactado filtra la URL por otro campo | omite carga, campos parseados y `effectiveUri`; conserva solo hash y hechos mínimos |
| Export de historial se confunde con evidencia redactada | advertencia y confirmación explícita antes de compartir JSON/CSV/XLSX completos |
| Checksum se interpreta como prueba de autoría | `assurance=checksum-only-not-authenticated`; documentación exige anclaje o firma externa |
| Regresión por dependencia | versiones fijadas, lockfile, CI, SBOM, inventario de licencias y actualizaciones individuales |
| Denegación de servicio por PDF/imagen | límites, progreso, cancelación, escalado y limpieza temporal |
| Migración destructiva | respaldo previo, transacción, verificación e idempotencia |

## Fuera de alcance

La aplicación no sustituye antivirus, reputación en línea, validación bancaria ni autenticidad de documentos oficiales. No se promete interpretar formatos privados o cifrados sin especificación.
