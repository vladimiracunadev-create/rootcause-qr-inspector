# Solución de problemas

## La cámara no aparece

- Comprueba que el sistema o navegador concedió permiso al sitio/aplicación.
- En PWA usa la URL HTTPS de GitHub Pages; una cámara web suele estar bloqueada
  en orígenes inseguros.
- Cierra otra aplicación que esté usando la cámara y vuelve a abrir el sensor.
- Si la plataforma no ofrece cámara nativa compatible, importa una imagen.

## El código no se reconoce o se repite

- Limpia la lente, aumenta la luz y evita reflejos o curvatura.
- Mantén el código completo dentro del marco y deja margen alrededor.
- Aleja la cámara si no logra enfocar.
- El estado visible y el tono indican captura; no seguridad del resultado.

## Un PDF no se procesa en la PWA

El renderer PDF de 0.1.0 no está disponible en web. Usa una imagen exportada del
PDF o ejecuta una plataforma nativa compatible. Esta limitación es deliberada y
se muestra en [`rootcause/LIMITATIONS.md`](rootcause/LIMITATIONS.md).

## La PWA muestra una página vacía o recursos 404

- Abre la ruta publicada completa:
  `https://vladimiracunadev-create.github.io/rootcause-qr-inspector/app/`.
- Fuerza recarga o elimina los datos del sitio si quedó un service worker de una
  versión anterior.
- Revisa el workflow **Deploy Landing Page**; `/app/` solo existe después de un
  build y despliegue correctos.

## El bloqueo biométrico no funciona

La plataforma debe tener autenticación local configurada y soportada por el
plugin. Si el almacén o autenticador no está disponible, inicia en modo temporal
desde la pantalla de recuperación y evita asumir persistencia segura.

## El historial está vacío

OTP, Wi-Fi con contraseña y URLs que parecen contener secretos no se guardan de
forma automática. El modo temporal también elimina datos al cerrar. Revisa la
retención configurada antes de tratarlo como pérdida.

## La aplicación aísla un registro

No edites la base manualmente. Usa **Recuperación** para inspeccionar el motivo y
aplicar la acción disponible. AES-GCM rechaza cargas manipuladas; aislar evita
que un registro dañado impida abrir el resto.

## No compila desde código fuente

1. confirma Flutter 3.44.7 y Dart 3.12 o superior;
2. ejecuta `flutter pub get` con el lockfile versionado;
3. genera las carpetas nativas con `python3 tool/bootstrap.py`;
4. ejecuta `python3 tool/validate_structure.py --require-lock`;
5. consulta [`quality/COMPATIBILITY_CONTRACT.md`](quality/COMPATIBILITY_CONTRACT.md)
   antes de actualizar una dependencia.

Para un fallo reproducible que no sea una vulnerabilidad, abre un issue con
plataforma, versión y pasos usando solo cargas sintéticas.
