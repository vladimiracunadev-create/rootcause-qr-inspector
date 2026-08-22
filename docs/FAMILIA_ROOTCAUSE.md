# RootCause QR Inspector dentro de la familia

## La idea común

> Diagnóstico primero; intervención después.

Cada edición observa una superficie distinta, produce hechos explicables y deja
visibles sus límites. RootCause QR Inspector añade la superficie **contenido
codificado antes de la entrega**: no observa todo el teléfono ni navega el sitio.

## Qué aporta esta edición

| Pregunta | Respuesta del sensor QR |
|---|---|
| Unidad observada | Una carga capturada desde cámara, imagen o PDF |
| Hechos | Estructura de URI, host, codificación, intención textual y tipo de acción |
| Hipótesis | Phishing, robo de credenciales, redirección o entrega riesgosa sospechados |
| Evidencia común | Instante, hash, ids estables, severidad, decisión y límites |
| Entrega a otra edición | Exportación explícita; no hay telemetría ni bus automático en 0.1.0 |

## Superficies complementarias

| Edición | Qué puede aportar después o alrededor del QR |
|---|---|
| [Web Inspector](https://github.com/vladimiracunadev-create/rootcause-web-inspector) | permisos, extensión, sesión, descarga y página que simula navegador |
| [Mobile Inspector](https://github.com/vladimiracunadev-create/rootcause-mobile-inspector) | cambios de apps, permisos y comportamiento del dispositivo |
| [Windows Inspector](https://github.com/vladimiracunadev-create/rootcause-windows-inspector) | procesos, persistencia, servicios, red y recursos |
| [macOS Inspector](https://github.com/vladimiracunadev-create/rootcause-macos-inspector) | launchd, TCC, Gatekeeper, XProtect, procesos y red |
| [Bitcoin Defense](https://github.com/vladimiracunadev-create/rootcause-bitcoin-defense) | procedencia y control de claves de custodia, no validez del QR |
| [Blockchain Security](https://github.com/vladimiracunadev-create/rootcause-blockchain-security) | privilegios, proxies, oráculos, puentes y gobernanza on-chain |

## Ejemplo de correlación

1. QR Inspector registra `redirect-nested-domain` y exporta el hash de la carga.
2. Web Inspector observa la navegación, permisos y descarga posteriores.
3. Mobile o un inspector de escritorio correlaciona el instante con cambios del
   dispositivo.
4. La persona investigadora conserva hechos de cada superficie sin convertir
   una sola señal en veredicto.

En 0.1.0 los pasos son manuales. El contrato futuro se bosqueja en
[`rootcause/INTEGRATION.md`](rootcause/INTEGRATION.md).

## Diferencias que no se disimulan

- Este repositorio usa MIT por su procedencia; otras ediciones Inspector usan
  Apache 2.0 y las de activos digitales también usan MIT.
- La PWA necesita red para recibir sus archivos desde GitHub Pages, aunque el
  análisis de la carga no envía telemetría.
- El sensor QR trabaja antes de la acción. No sustituye la observación posterior
  del navegador ni del sistema.
- Sus 26 reglas son específicas de cargas QR/códigos; no deben reutilizarse como
  si fueran reglas de procesos, contratos o custodia.
