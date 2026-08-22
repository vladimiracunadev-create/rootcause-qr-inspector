# Manual de usuario

## Antes de escanear

RootCause QR Inspector interpreta antes de actuar. Aun así, evita usar datos
reales durante una prueba y valida por un canal independiente cualquier pago,
credencial o beneficiario. Una lectura normal solo significa que no se activó
una regla local aplicable.

## Flujo recomendado

1. Abre **Escanear** y concede cámara solo si usarás captura en vivo.
2. Enmarca un código o elige una imagen/PDF iniciado por ti.
3. Espera el estado visible de lectura; el tono confirma una captura, no la
   seguridad del contenido.
4. Revisa tipo, destino, campos interpretados y hallazgos.
5. Distingue hechos de hipótesis antes de continuar.
6. Si el caso lo exige, exporta **Evidencia** en modo redactado.
7. Abre el destino solo cuando también lo hayas validado por otra fuente.

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

### Escanear

Captura con cámara o importa imágenes y PDF compatibles. Mantiene visible el
estado, evita acciones silenciosas y abre la hoja de resultado tras interpretar.

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
