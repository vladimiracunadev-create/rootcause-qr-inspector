# Estado de implementación · 0.2.0

## Mejoras incluidas en 0.2.0

| Capacidad | Estado verificable |
|---|---|
| Zona de lectura con pellizco | **IMPLEMENTADA:** amplitud continua, porcentaje visible, preferencia recordada y control equivalente en Ajustes; geometría cubierta por pruebas en toda su amplitud y en cuatro tamaños de vista previa. **Gesto no probado en teléfono físico** |
| Misma zona de lectura en Inventario | **IMPLEMENTADA:** el visor crece hasta el 58 % de la pantalla y cede alto a la lista; el marco deja de quedar bajo su barra de estado |
| Aviso de lectura sin progreso | **IMPLEMENTADO:** a los 7 s sugiere acercarse, a los 16 s ofrece la entrada por archivo; el motor no mueve el zoom por su cuenta |
| Identidad de dominio | **IMPLEMENTADA:** Public Suffix List completa (6948 reglas ICANN) y esqueleto UTS #39 con destino ASCII; reglas 27 y 28, dominio registrable como evidencia |
| Host Unicode | **CORREGIDO:** se analizaba percent-codificado, así que ningún hallazgo de identidad se disparaba con un host en otro alfabeto |
| Banco de regresión | **EJECUTADO:** los 16 fixtures pasan por el motor en `qr_fixtures_test.dart`; cierra R-01 |
| Acción visible `Analizar archivo` | **IMPLEMENTADA:** compacta sin reducir la altura fija del visor; geometría y accesibilidad pasan la suite, prueba física pendiente |
| Una o varias imágenes | **IMPLEMENTADA:** coordinador nativo, límite de 20 y 50 MiB por archivo; lógica y build Android verificados, fixture nativo pendiente |
| PDF multipágina | **MEJORADA:** límite de 50, total/truncación visibles, cancelación y limpieza probadas; raster adaptativo 4K y fixture Code 128 renderizado, decodificación en dispositivo pendiente |
| Destino semántico y host real | **VERIFICADO:** contratos existentes, pruebas unitarias y widget al 200 %; un resultado bloqueado no expone acción externa |
| Confirmación de lectura | **IMPLEMENTADA:** cámara, inventario, imágenes y PDF producen tono/vibración configurables; archivos confirman una vez por lote |
| Exportación para navegador | **IMPLEMENTADA:** Historial e Inventario exportan HTML autocontenido, escapado y con enlaces en pestaña nueva |
| Cámara, historial y acción externa | **SIN REGRESIONES EN SUITE:** se reutilizan motor, persistencia selectiva y política existentes; 163 pruebas aprobadas |
| Decodificación en web | **PLANIFICADO:** `mobile_scanner 7.4.0` no implementa `analyzeImage` web; la UI no afirma soporte |
| Idiomas | **IMPLEMENTADO:** sistema, español de Chile/internacional, inglés, francés y alemán; datos de usuario y cargas no se traducen |
| Ayuda de pestañas | **IMPLEMENTADA:** guía de las cinco superficies y tutorial contextual de Inventario, probado a 320 px y texto al 160 % |

La versión es `0.2.0+6` y el motor de reglas, `0.2.0`. La validación funcional de la matriz completa de
fixtures en hardware Android continúa pendiente y se declara como límite; no
impide publicar mejoras que ya pasan los gates automatizados del producto.

## Operativo en el código fuente

| Área | Estado |
|---|---|
| Captura | Cámara, imágenes y PDF por lotes; QR, 2D y códigos lineales heredados del lector universal. La detección cubre toda la vista previa y la resolución pedida se declara de forma explícita |
| Interpretación | URL, Wi-Fi, vCard/MeCard, eventos, OTP, GS1, ISBN, pagos, cripto, AAMVA y binario |
| Investigación | Motor local puro con 28 reglas, ids estables, severidad, puntos, confianza y evidencia mínima |
| Hipótesis | Seis hipótesis separadas de los hechos, incluido `qr-phishing-suspected` |
| Decisión | `allow`, `confirm`, `inspectOnly` o `block`; nunca “seguro” |
| Interfaz | Puntaje, ids técnicos, evidencia, hipótesis, límites y confirmación antes de actuar. Cinco estados visibles de cámara, tono/vibración también para archivos válidos; selector de cuatro idiomas, guía de pestañas e Inventario explicado; el generador diferencia contenido e imagen y descarga PNG/SVG en web |
| Evidencia | `rootcause.evidence.qr.v1`, SHA-256 de carga, checksum no autenticado del paquete, redacción por defecto y enlace opcional a un hash anterior |
| Datos | Historial/inventario cifrados con AES-256-GCM, llave en almacenamiento seguro, recuperación y modo temporal |
| Compatibilidad | Importa respaldos de RootCause QR Inspector y Universal Code Scanner; recalcula campos derivados de entradas no confiables |
| Política | El API del motor acepta marcas, dominios y umbrales; se incluye una configuración sintética de ejemplo |
| Privacidad | Análisis local y telemetría cero; exportación CSV/JSON/XLSX/HTML solo por acción de la persona y con advertencia de datos sin cifrar |

## Coherente y validado

- 28 reglas sincronizadas entre motor, textos, esquema y documentación.
- 16 fixtures sintéticos sin destinos reales operables.
- redacción verificada para impedir que `effectiveUri` reconstruya la carga;
- frase obligatoria para resultados normales;
- YAML, JSON, imports, enlaces, SBOM, versión y lockfile.
- 164 casos Dart/Flutter declarados (163 los ejecuta `flutter test`; uno es de
  integración y requiere dispositivo).

Para 0.2.0 se ejecutan análisis estático, 163 pruebas de `test/`, compilación
web release y APK release. La evidencia y los límites se registran en
[`VALIDATION.md`](VALIDATION.md).

## Parcial y declarado

- **Política organizacional:** puede inyectarse por API y tiene archivo de
  ejemplo; todavía no existe pantalla para importar, firmar o administrar esa
  política.
- **Unicode:** detecta presencia, mezcla básica Latin/Greek/Cyrillic y
  suplantación de escritura completa mediante el esqueleto UTS #39. El
  esqueleto es **parcial y declarado**: solo las equivalencias cuyo destino es
  ASCII, y sin normalización NFD, porque Dart no la trae.
- **Dominio registrable:** incorpora la Public Suffix List completa con su
  algoritmo —reglas comodín y excepciones incluidas—. La copia tiene fecha: un
  sufijo creado después no se reconoce y el dominio registrable sale más corto,
  que es el comportamiento conservador.
- **Integridad:** cada export tiene hash propio y puede enlazar manualmente el
  hash anterior; no es firma/MAC y el historial no construye automáticamente
  una cadena forense.

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
