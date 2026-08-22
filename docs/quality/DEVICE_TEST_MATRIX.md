# Matriz de pruebas en dispositivos

La versión se considera candidata estable solamente cuando todos los casos obligatorios estén registrados con modelo, sistema, resultado y evidencia.

| Área | Android gama baja | Android media | Android alta | iPhone compatible | macOS | Web |
|---|---:|---:|---:|---:|---:|---:|
| Inicio normal y modo seguro | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Cámara trasera/frontal | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Permiso denegado y revocado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Poca luz y enfoque | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Recomendado | Recomendado |
| Código pequeño, curvo y dañado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Recomendado | Recomendado |
| Varios códigos simultáneos | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| Galería y PDF de 1/10/25/50 páginas | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | No aplica |
| Biometría y regreso desde segundo plano | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | No aplica |
| Rotación de llave y reinstalación | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |
| XLSX en Excel/Sheets/LibreOffice | Una exportación por plataforma de escritorio y servicio objetivo |
| TalkBack/VoiceOver/teclado | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio | Obligatorio |

Los recursos reproducibles están en `test_assets/manifest.json`. Las simbologías no generadas de forma confiable deben incorporarse únicamente como capturas reales verificadas.

## Registro reproducible de v0.1.0

| Entorno | Artefacto | Instalación/inicio | Generar/importar/analizar | Ajustes | Cámara |
|---|---|---|---|---|---|
| AVD Medium Phone, Android 36.1 x86_64, 1080×2400 | APK público `v0.1.0`, SHA-256 `78ed8e2194488029218f73aa17fdfa0fb9075e1d0dd110db1981b16c4418c51b` | `adb install -r`: Success; actividad principal visible | QR para `https://example.com` generado, importado desde Photo Picker y analizado: `0/100`, sin declarar el destino seguro | apariencia, inspección, privacidad y seguridad: visibles | el sensor virtual del AVD no inició; la app mostró error recuperable |

Evidencia visual: [`android-inspector-home.png`](../images/android/android-inspector-home.png),
[`android-generator.png`](../images/android/android-generator.png) y
[`android-settings.png`](../images/android/android-settings.png), además del
[`resultado de análisis`](../images/android/android-analysis-result.png). Este registro no
sustituye las filas obligatorias en teléfonos físicos.
