# Límites y honestidad técnica

## Lo que un análisis local sí conoce

- bytes decodificados del código;
- simbología, fuente e instante;
- estructura sintáctica de la carga;
- esquema, autoridad, host, puerto, ruta y parámetros de una URL;
- señales Unicode simples en Latin, Greek y Cyrillic;
- formatos estructurados reconocidos por el parser;
- política local de marcas y dominios.

## Lo que no puede conocer sin red

- reputación actual del dominio o IP;
- fecha de registro o dueño del dominio;
- resolución DNS efectiva;
- certificado TLS que entregará el servidor;
- estado de navegación segura de un proveedor;
- cadena real de redirecciones HTTP;
- contenido que devolverá el sitio;
- si el dominio fue comprometido después de ser legítimo.

Estas ausencias aparecen en `investigation.limitations`; no se convierten en
“sin riesgo”.

## Lo que la carga no revela

El código decodificado no demuestra:

- que alguien pegó una etiqueta falsa encima del QR auténtico;
- dónde estaba físicamente el código;
- quién lo imprimió;
- si el comercio esperaba ese beneficiario;
- si un monto o cuenta coincide con una factura externa;
- si la persona recibió el QR mediante correo, SMS o una aplicación concreta.

Registrar y correlacionar ese contexto requiere otra superficie o una entrada
humana explícita.

## Falsos positivos previsibles

| Regla | Caso legítimo posible |
|---|---|
| `host-punycode` | dominio internacional válido |
| `host-unicode` | nombre legítimo en otro idioma |
| `host-ip-literal` | consola de administración propia |
| `host-private-or-local` | router, impresora o servicio interno autorizado |
| `host-shortener` | campaña legítima con medición |
| `host-deep-subdomains` | infraestructura corporativa compleja |
| `credential-lure-path` | acceso real de un servicio conocido |
| `tracking-excessive` | campaña publicitaria legítima |
| `payment-instruction` | pago real esperado por la persona |
| `host-hyphen-density` | dominio descriptivo legítimo |

Por eso los hallazgos incluyen confianza y no son veredictos de malicia.

## Unicode

La regla actual distingue presencia de caracteres y mezcla de tres rangos
generales. No implementa todavía el skeleton completo ni los perfiles de
restricción de Unicode UTS #39. Se denomina heurística y no conformidad UTS #39.

## Dominio registrable

La familia de host para redirecciones se aproxima mediante relación de sufijo.
No incorpora la Public Suffix List en 0.1.0. Por eso evita afirmar que calculó
un eTLD+1 normativo.

## Puntaje

El puntaje suma pesos declarados y se limita a 100. Sirve para ordenar y
comparar evidencia; no es una probabilidad de fraude. La severidad global es el
máximo de los hallazgos y no se deduce del porcentaje.

## Integridad de evidencia

`bundleHash` es un checksum SHA-256 sin clave. Verifica consistencia interna
cuando la huella esperada se obtuvo por una ruta confiable, pero cualquiera que
modifique el JSON también puede recalcularlo. No es firma digital, MAC, sello de
tiempo ni prueba de autoría. `previousEvidenceHash` tampoco forma por sí solo
una cadena autenticada.

## Plataformas

- Android: cámara real y biometría requieren prueba en dispositivo físico.
- iOS: compilación y permisos requieren entorno Apple y firma para distribución.
- Web: es un canal de demostración; el origen y las políticas del navegador
  condicionan cámara y almacenamiento seguro.
- Windows, macOS y Linux: no aplican; no son plataformas objetivo del producto.

## Distribución

La 0.1.0 publica un APK Android directo en GitHub con checksum. No incluye ficha
de Play Store/App Store ni paquete iOS instalable. El soporte de distribución se
limita a las aplicaciones móviles Android/iOS.

## Frase de salida obligatoria

Cuando no hay hallazgos, la UI debe decir:

> No se observaron señales locales. Esto no demuestra que el destino sea seguro.

Eliminar esa frase sería una regresión de seguridad y debe fallar en revisión.
