# Política de privacidad de referencia

RootCause QR Inspector procesa los códigos localmente. El proyecto no incorpora publicidad, analítica, cuentas, servidores propios ni venta de datos.

## Datos locales

- Configuración: preferencias locales.
- Historial: cifrado antes de almacenarse.
- Inventarios: cifrados antes de almacenarse.
- Llave de cifrado: almacén seguro del sistema operativo.
- Imágenes y PDF: se leen por selección explícita; las páginas temporales renderizadas se eliminan al finalizar.

## Acciones externas

Abrir un enlace, correo, llamada, SMS, mapa o compartir contenido entrega información a la aplicación externa seleccionada y queda sujeto a la política de esa aplicación.

## Contenido sensible

OTP, redes Wi-Fi con contraseña y URLs cuyos parámetros parecen contener
tokens, secretos, credenciales o firmas se excluyen del historial automático.
El usuario puede copiar o compartir el resultado inmediato bajo su
responsabilidad; el proyecto muestra advertencias y ofrece borrado temporal del
portapapeles.

El export de evidencia omite por defecto la carga cruda, los campos
interpretados y la URL efectiva. Conserva una huella SHA-256 para correlación.
Incluir el contenido completo requiere una acción explícita.

Los respaldos y exports completos del historial (JSON, CSV y XLSX) sí contienen
las cargas y metadatos descifrados. La interfaz lo advierte y exige confirmación
antes de abrir el selector de compartir.

Antes de publicar, el responsable de la aplicación debe adaptar este texto a su identidad legal, país, tienda y cualquier servicio adicional que incorpore.
