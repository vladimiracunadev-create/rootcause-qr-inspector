# Estado de implementación · 0.1.0

## Operativo en el código fuente

| Área | Estado |
|---|---|
| Captura | Cámara, imágenes y PDF por lotes; QR, 2D y códigos lineales heredados del lector universal |
| Interpretación | URL, Wi-Fi, vCard/MeCard, eventos, OTP, GS1, ISBN, pagos, cripto, AAMVA y binario |
| Investigación | Motor local puro con 26 reglas, ids estables, severidad, puntos, confianza y evidencia mínima |
| Hipótesis | Seis hipótesis separadas de los hechos, incluido `qr-phishing-suspected` |
| Decisión | `allow`, `confirm`, `inspectOnly` o `block`; nunca “seguro” |
| Interfaz | Puntaje, ids técnicos, evidencia, hipótesis, límites y confirmación antes de actuar |
| Evidencia | `rootcause.evidence.qr.v1`, SHA-256 de carga, checksum no autenticado del paquete, redacción por defecto y enlace opcional a un hash anterior |
| Datos | Historial/inventario cifrados con AES-256-GCM, llave en almacenamiento seguro, recuperación y modo temporal |
| Compatibilidad | Importa respaldos de RootCause QR Inspector y Universal Code Scanner; recalcula campos derivados de entradas no confiables |
| Política | El API del motor acepta marcas, dominios y umbrales; se incluye una configuración sintética de ejemplo |
| Privacidad | Análisis local y telemetría cero; exportación solo por acción de la persona |

## Coherente y validado offline

- 26 reglas sincronizadas entre motor, textos, esquema y documentación.
- 12 fixtures sintéticos sin destinos reales operables.
- redacción verificada para impedir que `effectiveUri` reconstruya la carga;
- frase obligatoria para resultados normales;
- YAML, JSON, imports, enlaces, SBOM, versión y lockfile.

La suite Flutter de 77 casos está incluida, pero no se ejecutó en el entorno de
ensamblado porque Flutter/Dart no estaban instalados. Ver [`VALIDATION.md`](VALIDATION.md).

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

## Requiere validación de runtime

- análisis estático y suite Flutter completa;
- build Android/PWA y compilación iOS/macOS;
- cámara, enfoque, poca luz, etiquetas curvas/dañadas y lotes grandes;
- ciclo de vida, biometría, Keychain/Keystore y recuperación;
- accesibilidad con TalkBack/VoiceOver;
- apertura externa y confirmaciones en cada plataforma.

## Próximas capas, no presentes

- reputación, DNS, certificados, edad de dominio y redirecciones reales con
  consentimiento y política de privacidad propios;
- detección visual de etiquetas superpuestas;
- correlación automática con RootCause Mobile/Web;
- validación independiente de beneficiario o factura;
- política organizacional firmada y administrable;
- firma de binarios, publicación en tiendas y servicio de actualización.
