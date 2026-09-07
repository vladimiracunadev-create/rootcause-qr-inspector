# Estado de implementación · 0.1.2

## Evolución de inspección de archivos (no publicada)

| Capacidad | Estado verificable |
|---|---|
| Acción visible `Analizar archivo` | **IMPLEMENTADA:** compacta sin reducir la altura fija del visor; geometría y accesibilidad pasan la suite, prueba física pendiente |
| Una o varias imágenes | **IMPLEMENTADA:** coordinador nativo, límite de 20 y 50 MiB por archivo; lógica y build Android verificados, fixture nativo pendiente |
| PDF multipágina | **IMPLEMENTADA:** límite de 50, total/truncación visibles, cancelación y limpieza probadas; fixture renderizado, decodificación en dispositivo pendiente |
| Destino semántico y host real | **VERIFICADO:** contratos existentes, pruebas unitarias y widget al 200 %; un resultado bloqueado no expone acción externa |
| Cámara, historial y acción externa | **SIN REGRESIONES EN SUITE:** se reutilizan motor, persistencia selectiva y política existentes; 102 pruebas aprobadas |
| Decodificación en web | **PLANIFICADO:** `mobile_scanner 7.4.0` no implementa `analyzeImage` web; la UI no afirma soporte |

La versión permanece en `0.1.2+3`. No se preparará `0.1.3` hasta completar
la validación funcional de fixtures en un dispositivo Android.

## Operativo en el código fuente

| Área | Estado |
|---|---|
| Captura | Cámara, imágenes y PDF por lotes; QR, 2D y códigos lineales heredados del lector universal. La detección cubre toda la vista previa y la resolución pedida se declara de forma explícita |
| Interpretación | URL, Wi-Fi, vCard/MeCard, eventos, OTP, GS1, ISBN, pagos, cripto, AAMVA y binario |
| Investigación | Motor local puro con 26 reglas, ids estables, severidad, puntos, confianza y evidencia mínima |
| Hipótesis | Seis hipótesis separadas de los hechos, incluido `qr-phishing-suspected` |
| Decisión | `allow`, `confirm`, `inspectOnly` o `block`; nunca “seguro” |
| Interfaz | Puntaje, ids técnicos, evidencia, hipótesis, límites y confirmación antes de actuar. Cinco estados visibles de cámara, incluida la confirmación explícita `Código leído`; el generador diferencia contenido e imagen y descarga PNG/SVG en web |
| Evidencia | `rootcause.evidence.qr.v1`, SHA-256 de carga, checksum no autenticado del paquete, redacción por defecto y enlace opcional a un hash anterior |
| Datos | Historial/inventario cifrados con AES-256-GCM, llave en almacenamiento seguro, recuperación y modo temporal |
| Compatibilidad | Importa respaldos de RootCause QR Inspector y Universal Code Scanner; recalcula campos derivados de entradas no confiables |
| Política | El API del motor acepta marcas, dominios y umbrales; se incluye una configuración sintética de ejemplo |
| Privacidad | Análisis local y telemetría cero; exportación solo por acción de la persona |

## Coherente y validado

- 26 reglas sincronizadas entre motor, textos, esquema y documentación.
- 12 fixtures sintéticos sin destinos reales operables.
- redacción verificada para impedir que `effectiveUri` reconstruya la carga;
- frase obligatoria para resultados normales;
- YAML, JSON, imports, enlaces, SBOM, versión y lockfile.
- 103 casos Dart/Flutter declarados (102 los ejecuta `flutter test`; uno es de
  integración y requiere dispositivo).

Para la línea base publicada 0.1.2 se ejecutaron análisis estático, 87 pruebas de
`test/`, compilación web release y una prueba funcional de descarga PNG/SVG en
localhost. El addendum no publicado eleva la suite local a 102 y también pasa
web/APK release. La evidencia y los límites se registran en
[`VALIDATION.md`](VALIDATION.md).

## Parcial y declarado

- **Política organizacional:** puede inyectarse por API y tiene archivo de
  ejemplo; todavía no existe pantalla para importar, firmar o administrar esa
  política.
- **Unicode:** detecta presencia y mezcla básica Latin/Greek/Cyrillic; no
  implementa aún skeleton ni perfiles completos UTS #39.
- **Dominio registrable:** compara familias por sufijo; no incorpora Public
  Suffix List.
- **Integridad:** cada export tiene hash propio y puede enlazar manualmente el
  hash anterior; no es firma/MAC y el historial no construye automáticamente
  una cadena forense.
- **Idioma:** interfaz en español; la infraestructura de localización heredada
  no cubre todavía todos los textos nuevos.

## Requiere validación en hardware y distribución

- **la corrección de lectura de 0.1.1**: código lejano y descentrado,
  confirmación de captura, relectura del mismo código y conteo de unidades
  repetidas en inventario;
- cámara, enfoque, poca luz, etiquetas curvas/dañadas y lotes grandes;
- ciclo de vida, biometría, Keychain/Keystore y recuperación;
- accesibilidad con TalkBack/VoiceOver;
- apertura externa y confirmaciones en cada plataforma.
- firma de producción y prueba de los binarios distribuibles.

## Próximas capas, no presentes

- reputación, DNS, certificados, edad de dominio y redirecciones reales con
  consentimiento y política de privacidad propios;
- detección visual de etiquetas superpuestas;
- correlación automática con RootCause Mobile/Web;
- validación independiente de beneficiario o factura;
- política organizacional firmada y administrable;
- firma de binarios, publicación en tiendas y servicio de actualización.
