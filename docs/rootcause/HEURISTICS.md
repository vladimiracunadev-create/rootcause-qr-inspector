# Heurísticas del motor QR

Este documento es el contrato humano de
`lib/core/investigation/qr_investigation_engine.dart`. Cada regla debe tener:

1. id estable y neutral al idioma;
2. condición exacta;
3. severidad y puntos;
4. evidencia mínima;
5. test positivo y, cuando corresponde, negativo;
6. límite o falso positivo declarado.

## Modelo de salida

```text
severidad_global = max(severidad de hallazgos)
puntaje_global   = min(100, suma de puntos)
```

El puntaje no es probabilidad. La severidad no se obtiene del puntaje.

## Las 28 reglas

| # | Id | Condición | Sev. | Pts. | Confianza | Evidencia |
|---:|---|---|---|---:|---|---|
| 1 | `transport-http` | esquema `http` | warning | 8 | alta | esquema |
| 2 | `authority-userinfo` | `userinfo` o `@` en autoridad | critical | 25 | alta | host real |
| 3 | `host-punycode` | alguna etiqueta comienza `xn--` | critical | 20 | media | host normalizado |
| 4 | `host-mixed-script` | host mezcla Latin/Greek/Cyrillic | critical | 25 | alta | host normalizado |
| 5 | `host-unicode` | host contiene rune > 127 | warning | 5 | baja | host normalizado |
| 6 | `host-ip-literal` | IPv4 o IPv6 literal | warning | 8 | alta | host |
| 7 | `host-private-or-local` | loopback, rangos privados, link-local, `.local`, `.internal` | critical | 20 | alta | host |
| 8 | `host-shortener` | host coincide con catálogo local de acortadores | warning | 10 | alta | host |
| 9 | `host-deep-subdomains` | etiquetas > `maxDomainLabels` (5 por defecto) | warning | 5 | media | cantidad |
| 10 | `host-trailing-dot` | autoridad termina el host con `.` | warning | 3 | media | host |
| 11 | `host-hyphen-density` | ≥ 4 guiones totales o ≥ 3 en una etiqueta | warning | 3 | baja | host |
| 12 | `host-empty` | URL web sin host | critical | 40 | alta | id de regla |
| 13 | `port-unusual` | puerto explícito distinto de 80/443 | warning | 6 | alta | puerto |
| 14 | `url-excessive-length` | longitud > `maxUrlLength` (240) | warning | 4 | media | longitud |
| 15 | `url-control-character` | control, DEL, bidi/invisible o control porcentual (`%00`–`%1f`, `%7f`) en cualquier URI accionable | critical | 35 | alta | id de regla |
| 16 | `authority-obfuscated` | barra invertida, espacio/control o varios `@` | critical | 30 | alta | host |
| 17 | `encoded-separator` | `%2f`, `%5c`, `%40`, `%3a` o doble codificación en autoridad | critical | 20 | alta | host |
| 18 | `download-dangerous-extension` | ruta decodificada termina en extensión catalogada | critical | 25 | alta | extensión |
| 19 | `credential-lure-path` | ruta/consulta contiene token de acceso, cuenta, banco, clave, MFA o verificación | warning | 8 | media | host |
| 20 | `tracking-excessive` | ≥ 3 parámetros `utm_*`, `gclid`, `fbclid`, `mc_*` o `ref` | warning | 3 | alta | nombres de parámetros |
| 21 | `redirect-nested-domain` | parámetro de redirección contiene URL de otra familia de host | critical | 20 | alta | parámetro + host destino |
| 22 | `brand-domain-mismatch` | token configurado aparece fuera de hosts permitidos | critical | 30 | alta | marca + token + host |
| 23 | `scheme-blocked` | esquema declarado no es web, acción segura ni estructura conocida | critical | 35 | alta | esquema |
| 24 | `sensitive-secret` | OTP o `otpauth:` | warning | 5 | alta | tipo de contenido |
| 25 | `payment-instruction` | pago EMV/EPC/Swiss/cripto | warning | 5 | alta | tipo de contenido |
| 26 | `opaque-binary-payload` | carga binaria/Base64 sin interpretación | warning | 8 | alta | id de regla |
| 27 | `host-whole-script-confusable` | host no ASCII cuyo esqueleto UTS #39 es ASCII puro y usa alguna escritura no latina | critical | 28 | alta | host normalizado + lectura latina equivalente |
| 28 | `host-embedded-suffix` | sufijo público ICANN de ≥ 3 caracteres, o de dos etiquetas, escrito antes del dominio registrable | warning | 12 | media | host + sufijo incrustado + dominio registrable |

## Identidad del dominio: las dos reglas de 0.2.0

Ambas responden a la misma pregunta con datos que antes el motor no tenía: el
host **es** el que la persona cree que es.

### `host-whole-script-confusable`

`host-mixed-script` detecta la **mezcla**: una `о` cirílica dentro de una
palabra latina. No ve el caso contrario, que es más limpio y más eficaz: un host
escrito **entero** en una sola escritura no latina que se lee como una marca
latina. Ese host no mezcla nada y hasta 0.1.4 solo producía `host-unicode`, de
confianza baja, el mismo hallazgo que un dominio internacional legítimo.

La regla calcula el esqueleto de UTS #39 —cada carácter sustituido por su
equivalente ASCII declarado por Unicode— y dispara cuando el esqueleto es ASCII
puro y al menos un carácter viene de una escritura no latina.

Límites declarados:

- la tabla incluye **solo** las equivalencias cuyo destino es ASCII, porque una
  equivalencia entre dos escrituras no latinas no suplanta a una marca latina;
- **no** hay normalización NFD: Dart no la trae, así que un carácter
  precompuesto ausente de la tabla se queda como está;
- el latín con diacríticos —`café`, `piñón`— **no** es confuso. Es escritura
  legítima del idioma, y tratarla como engaño volvería sospechosa a media
  internet hispanohablante.

### `host-embedded-suffix`

El patrón es `pago.com.atacante.example`: el dominio de primer nivel que la
persona reconoce aparece como etiqueta intermedia, donde no manda nada. Con la
Public Suffix List el motor ya sabe cuál es el dominio registrable —el que
alguien registró de verdad— y puede afirmar que el resto es decorado.

Límite declarado: **no** se disparan los ccTLD de dos letras. `es.`, `de.`,
`uk.` y `cl.` son subdominios de idioma o de región completamente normales
—`es.ejemplo.com`—, y tratarlos como suplantación convertiría el hallazgo en
ruido. Se pierden así los ataques que incrustan un ccTLD corto; a cambio, lo que
el hallazgo afirma se sostiene.

### Lo que la lista de sufijos cambió además

`redirect-nested-domain` comparaba «familias» de host por texto: un host era
familia de otro si uno terminaba en el otro. Eso daba por familia a
`ejemplo.com` y `malo-ejemplo.com.atacante.example`, y separaba a dos
subdominios del mismo dueño. Ahora compara **dominios registrables**.

`brand-domain-mismatch` compara el token de marca con el esqueleto del host, así
que una marca escrita en cirílico deja de esquivar su propio token.

El dominio registrable se adjunta como evidencia en `host-deep-subdomains` y en
`host-embedded-suffix`: es el dato que contesta la pregunta que el hallazgo
plantea.

## Catálogo de descarga

Extensiones en 0.1.1:

```text
7z aab apk appx bat cmd com dmg exe hta iso jar js jse lnk
msi pkg ps1 rar scr vbs wsf zip
```

Una extensión es un indicio sobre la ruta, no una prueba sobre los bytes que el
servidor devolverá. Sin red no se comprueba MIME, hash ni contenido.

## Tokens de credenciales

Se comparan contra ruta y consulta en minúsculas:

```text
access account auth banco bank clave credential cuenta login mfa oauth
password reset secure sesion signin sso token unlock validar verification
verify wallet
```

La regla es warning porque esos términos también aparecen en accesos legítimos.
Solo deriva `credential-theft-suspected` cuando coexiste con una señal de
identidad/ocultación de destino.

## Hipótesis derivadas

| Id | Condición mínima |
|---|---|
| `qr-phishing-suspected` | Punycode, mixed-script, userinfo, marca fuera de dominio, acortador o redirección externa |
| `credential-theft-suspected` | `credential-lure-path` + una señal anterior |
| `malware-delivery-suspected` | `download-dangerous-extension` |
| `payment-substitution-review` | `payment-instruction` |
| `local-network-lure` | `host-private-or-local` |
| `unsafe-uri-execution` | `scheme-blocked` |

Las hipótesis nunca añaden puntos. El puntaje se explica exclusivamente por
hallazgos.

## Política de acción

| Condición | Decisión |
|---|---|
| esquema no permitido | `block` |
| host vacío | `block` |
| caracteres de control/invisibles | `block` |
| autoridad ambigua | `block` |
| URL interpretable con hallazgos | `confirm` |
| URL interpretable sin hallazgos | `allow` |
| `mailto/tel/sms/geo` | `confirm` |
| estructura sin acción externa | `inspectOnly` |

## Evolución

Agregar una regla requiere cambiar en la misma entrega:

- motor;
- `QrFindingText`;
- este documento;
- esquema si restringe ids;
- fixture sintético;
- prueba positiva;
- prueba negativa cuando exista una excepción legítima;
- versión del motor.

Cambiar pesos o condiciones sin subir `engineVersion` está prohibido porque dos
exports iguales dejarían de ser comparables.
