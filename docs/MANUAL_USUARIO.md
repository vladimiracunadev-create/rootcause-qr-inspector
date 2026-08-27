# Manual de usuario

## Inspeccionar un QR ahora

Para Android 7 o posterior, descarga el APK público desde
[`GitHub Release v0.1.1`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.1)
o usa la
[`descarga directa`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/download/v0.1.1/rootcause-qr-inspector-v0.1.1-android.apk).
Android puede pedir autorización para instalar desde el navegador o gestor de
archivos usado. El Release incluye el archivo `.sha256` para comprobar la
descarga.

La demo técnica web está disponible en
[`https://vladimiracunadev-create.github.io/rootcause-qr-inspector/app/`](https://vladimiracunadev-create.github.io/rootcause-qr-inspector/app/).
No se considera una aplicación soportada ni sustituye las pruebas móviles. Las
únicas aplicaciones objetivo son Android e iOS, con cámara, imágenes y PDF
según las capacidades de cada sistema.

## Antes de inspeccionar

RootCause QR Inspector interpreta antes de actuar. Aun así, evita usar datos
reales durante una prueba y valida por un canal independiente cualquier pago,
credencial o beneficiario. Una lectura normal solo significa que no se activó
una regla local aplicable.

## Flujo recomendado

1. Abre **Escanear** y concede cámara solo si usarás captura en vivo.
2. Apunta al código o elige una imagen/PDF iniciado por ti. El marco central es
   una guía de encuadre: la lectura analiza toda la imagen, así que un código
   que se ve completo en pantalla se lee aunque quede fuera del cuadrado.
3. Cuando el código se lee, el estado cambia a **Código leído**, suena el tono,
   vibra el teléfono y se abre el análisis. El tono confirma una captura, no la
   seguridad del contenido.
4. No necesitas tocar el visor para activar la lectura. Usa **Pausar** y
   **Reanudar** cuando quieras detener o recuperar explícitamente la cámara.
5. Revisa tipo, destino, campos interpretados y hallazgos.
6. Distingue hechos de hipótesis antes de continuar.
7. Si el caso lo exige, exporta **Evidencia** en modo redactado.
8. Abre el destino solo cuando también lo hayas validado por otra fuente.

## Cómo leer el resultado

| Elemento | Significado |
|---|---|
| Hallazgo | Hecho observable, como HTTP, Punycode, IP privada o `userinfo` |
| Severidad | Prioridad técnica del hallazgo; no probabilidad de fraude |
| Puntaje | Ordena señales locales; no es porcentaje |
| Hipótesis | Explicación que merece investigación, nunca acusación |
| Decisión | Permitir, confirmar, solo inspeccionar o bloquear URI ambigua |
| Límite | Información que el sensor no puede conocer localmente |

## Secciones de la aplicación

### Inspeccionar

Es la superficie principal del producto de seguridad. Captura con cámara o
importa imágenes y PDF compatibles, mantiene visible el estado, evita acciones
silenciosas y abre el resultado de seguridad tras interpretar.

Si vuelves a apuntar al código que acabas de inspeccionar, la barra avisa de que
ya se inspeccionó en vez de quedarse callada. Aparta la cámara un momento y
vuelve a apuntar para leerlo de nuevo. Un código distinto se lee al instante.

Si un código no se lee, acércate o usa el deslizador de zoom: la cámara pide la
mayor resolución disponible, pero un código muy pequeño o muy lejano sigue
teniendo un límite físico.

### Inventario

Agrupa conteos en una sesión local. Sirve para operación y trazabilidad; no
convierte los códigos en una base remota.

### Generar

Crea códigos a partir de contenido introducido por la persona. Generar una carga
no la valida ni la vuelve segura.

### Historial

Muestra registros que pasaron la política de persistencia. OTP, Wi-Fi con
contraseña y URLs que parecen incluir secretos no se guardan automáticamente.

### Ajustes

Controla confirmación, retención, tema, accesibilidad, biometría y mantenimiento
de datos. El modo temporal evita conservar historial e inventarios al cerrar.

## Evidencia y exportaciones

La evidencia redactada conserva hash, tamaño, motor, ids, severidad, hipótesis,
reglas evaluadas y límites; omite carga, campos y URL efectiva. JSON, CSV o XLSX
de otras funciones pueden contener contenido descifrado: protégelos fuera de la
aplicación.

## Si algo falla

Consulta [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md). Para entender por qué un
caso produjo una señal, usa [`rootcause/HEURISTICS.md`](rootcause/HEURISTICS.md).
