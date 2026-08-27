# Matriz de pruebas en dispositivos

La versión se considera candidata estable solamente cuando todos los casos obligatorios estén registrados con modelo, sistema, resultado y evidencia.

| Área | Android gama baja | Android media | Android alta | iPhone | Tablet Android | iPad |
|---|---:|---:|---:|---:|---:|---:|
| Inicio normal y modo seguro | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Cámara trasera/frontal | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Permiso denegado y revocado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Poca luz y enfoque | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Código pequeño, curvo y dañado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Código lejano y fuera del marco central | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Confirmación de captura: tono, vibración y estado `Código leído` | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Relectura del mismo código tras cerrar el resultado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Inventario: diez unidades del mismo código | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Varios códigos simultáneos | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Galería y PDF de 1/10/25/50 páginas | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Biometría y regreso desde segundo plano | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Rotación/orientación y diseño adaptable | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Rotación de llave y reinstalación | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| TalkBack/VoiceOver | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |

La matriz cubre solo aplicaciones móviles. Las columnas de tablet son requisitos
pendientes y no una declaración de compatibilidad. Windows, macOS, Linux y web no son
columnas de aceptación del producto; la compatibilidad de archivos exportados
se verifica por separado y no convierte al escritorio en plataforma objetivo.

Los recursos reproducibles están en `test_assets/manifest.json`. Las simbologías no generadas de forma confiable deben incorporarse únicamente como capturas reales verificadas.

## Pendiente en v0.1.1

Las cuatro filas añadidas para la corrección de lectura de 0.1.1 —código lejano
y descentrado, confirmación de captura, relectura y conteo de unidades
repetidas— **no tienen todavía ningún registro**. La resolución de captura y el
modo de detección son configuración de plataforma: ninguna prueba automatizada
puede sustituir un teléfono. Ver [`../releases/v0.1.1.md`](../releases/v0.1.1.md).

## Registro reproducible de v0.1.0

| Entorno | Artefacto | Instalación/inicio | Generar/importar/analizar | Ajustes | Cámara |
|---|---|---|---|---|---|
| AVD Medium Phone, Android 36.1 x86_64, 1080×2400 | APK actualizado `v0.1.0`, SHA-256 `d1f765a9a61f235cf0f9825d594abb7e37d0c60c98f167f66aef95e41e6c5a34` | instalación limpia `Success`; paquete y actividad principal visibles | QR para `https://example.com` generado, importado desde Photo Picker y analizado: `0/100`, sin declarar el destino seguro | lectura automática, `Pausar`, `Reanudar`, navegación y retorno a lectura visibles | sensor virtual activo; no aparece una instrucción ni gesto oculto para tocar el visor |
| Android 36.1 x86_64, viewport tablet 1600×2560/320 dpi | mismo APK público `v0.1.0` | reinstalación `Success`; `MainActivity` visible | Generador visible y adaptable, sin desbordes | navegación inferior y acciones visibles | hardware físico de tablet no comprobado |

Evidencia visual: [`android-inspector-home.png`](../images/android/android-inspector-home.png),
[`android-inspector-paused.png`](../images/android/android-inspector-paused.png),
[`android-generator.png`](../images/android/android-generator.png) y
[`android-settings.png`](../images/android/android-settings.png), además del
[`resultado de análisis`](../images/android/android-analysis-result.png) y el
[`layout tablet`](../images/android/android-tablet-generator.png). Este registro no
sustituye las filas obligatorias en teléfonos físicos.
