# Manual de usuario

## Inspeccionar un QR ahora

### Desde una imagen o PDF

1. Toca **Analizar archivo** en el encabezado de Inspeccionar.
2. Elige **Elegir imagen**, **Elegir varias imágenes** o **Elegir PDF**.
3. Revisa el progreso; puedes usar **Cancelar** sin guardar resultados
   parciales silenciosamente.
4. En cada resultado lee **Qué se encontró**, **Qué contiene**, el destino
   semántico y, para enlaces, el **HOST REAL**.
5. Solo después decide si copiar, compartir o continuar con una aplicación
   externa. RootCause nunca abre el contenido por detectarlo.

Si no se detecta un código legible, prueba una imagen de mayor resolución y
comprueba que el código completo sea visible. El mensaje no demuestra que el
archivo carezca de códigos; indica únicamente que no fue posible detectarlos.

Los PDF mayores de 50 páginas muestran el total y dejan claro que solo se
inspeccionan las primeras 50. En web esta capacidad está **PLANIFICADA**.

Para Android 7 o posterior, descarga el APK público desde
[`GitHub Release v0.1.4`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/tag/v0.1.4)
o usa la
[`descarga directa`](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/releases/download/v0.1.4/rootcause-qr-inspector-v0.1.4-android.apk).
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
3. Cuando el código se valida, el estado cambia a **Código leído**, suena el
   tono, vibra el teléfono y se abre el análisis. La confirmación se aplica
   también a imágenes y PDF, una vez por lote; confirma una lectura, no la
   seguridad del contenido.
4. No necesitas tocar el visor para activar la lectura. Usa **Pausar** y
   **Reanudar** cuando quieras detener o recuperar explícitamente la cámara.
5. Revisa tipo, destino, campos interpretados y hallazgos.
6. Distingue hechos de hipótesis antes de continuar.
7. Si el caso lo exige, exporta **Evidencia** en modo redactado.
8. Abre el destino solo cuando también lo hayas validado por otra fuente.

Los enlaces web se abren en el navegador y, en la demo web, en una pestaña
nueva. Historial e Inventario pueden exportarse como **HTML para navegador**;
los enlaces del archivo se abren también en pestaña nueva. La exportación no
está cifrada, igual que CSV, JSON y XLSX, por lo que debe tratarse como sensible.

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

Agrupa conteos en una sesión local. Sirve para contar unidades físicas y
trazarlas sin convertir los códigos en una base remota. Un **código único** es
un producto distinto; una **unidad** es cada caja, envase o artículo que
escaneas, aunque varias unidades compartan exactamente el mismo código.

1. Abre **Inventario** y toca **Cómo usar Inventario** cuando necesites volver
   a ver la explicación dentro de la aplicación.
2. Escribe un nombre reconocible, por ejemplo “Bodega central agosto”, y toca
   **Iniciar inventario**.
3. Escanea cada unidad física. Diez cajas con el mismo código deben sumar diez
   unidades y un solo código único.
4. Revisa la cantidad de cada producto, agrega una nota si hace falta y elimina
   una entrada incorrecta antes de cerrar.
5. Toca **Cerrar sesión** al terminar. La sesión queda guardada y puede
   exportarse como CSV, JSON o Excel XLSX, pero ya no recibe nuevas lecturas a
   menos que la reabras.

**Importar JSON** muestra una vista previa y crea una copia; no sustituye una
sesión existente de forma silenciosa. El inventario se cifra localmente cuando
la persistencia está activa y se elimina al cerrar la aplicación en modo
temporal.

### Generar

Crea códigos a partir de contenido introducido por la persona. Generar una carga
no la valida ni la vuelve segura.

- **Copiar contenido** lleva al portapapeles el texto o la URL codificada; no
  copia la imagen ni abre el destino.
- **Compartir contenido** entrega ese texto a otra aplicación.
- En la demo web, **Descargar PNG** y **Descargar SVG** guardan la imagen en el
  equipo. En Android/iOS, **Compartir PNG/SVG** abre la hoja del sistema para
  guardarla o enviarla.

El código generado no tiene una fecha de expiración incorporada. Si contiene
una URL, seguirá funcionando solo mientras esa dirección, redirección o token
permanezca vigente.

### Historial

Muestra registros que pasaron la política de persistencia. OTP, Wi-Fi con
contraseña y URLs que parecen incluir secretos no se guardan automáticamente.

### Ajustes

Controla confirmación, retención, tema, accesibilidad, biometría y mantenimiento
de datos. En **Idioma** puedes seguir el idioma del sistema o elegir español de
Chile, español internacional, inglés, francés o alemán. El cambio es inmediato
y la preferencia permanece en el dispositivo. Las cargas escaneadas, nombres y
notas escritos por la persona no se traducen ni modifican.

**Guía rápida de la aplicación** abre una pantalla que resume Inspeccionar,
Inventario, Generar, Historial y Ajustes. La tarjeta de Inventario incluye los
cuatro pasos operativos y también puede abrirse desde el icono de ayuda de esa
pestaña.

El modo temporal evita conservar historial e inventarios al cerrar.

## Evidencia y exportaciones

La evidencia redactada conserva hash, tamaño, motor, ids, severidad, hipótesis,
reglas evaluadas y límites; omite carga, campos y URL efectiva. JSON, CSV o XLSX
de otras funciones pueden contener contenido descifrado: protégelos fuera de la
aplicación.

## Si algo falla

Consulta [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md). Para entender por qué un
caso produjo una señal, usa [`rootcause/HEURISTICS.md`](rootcause/HEURISTICS.md).
