# Detección de amenazas

> **¿Tienes un QR dudoso?** Abre el
> [inspector público](https://vladimiracunadev-create.github.io/rootcause-qr-inspector/app/)
> para ver la carga antes de actuar. El resultado describe señales locales y
> límites; no certifica que el destino sea seguro.

## Qué significa “detectar” en este repositorio

El sensor no detecta una campaña ni atribuye intención. Detecta propiedades de
una carga que aumentan el costo de verificación o habilitan una acción sensible.
La hipótesis aparece después y conserva lenguaje de sospecha.

## Mapa de cobertura local

| Riesgo investigado | Señales observables | Frontera |
|---|---|---|
| Suplantación de host | Punycode, Unicode, alfabetos mezclados, IP, subdominios, guiones, política de marca | No conoce dueño, edad ni reputación |
| Autoridad engañosa | `userinfo`, host vacío, caracteres de control, separadores codificados, barras o `@` ambiguos | No navega ni ve la barra final del navegador |
| Transporte débil | HTTP y puertos inusuales | No inspecciona el certificado servido |
| Redirección | URL anidada que cambia de familia de host | No sigue redirecciones HTTP reales |
| Robo de credenciales | Rutas de acceso, verificación, cuenta, banco, contraseña o MFA | La presencia de palabras no prueba intención |
| Entrega de archivo | Extensiones ejecutables, scripts, instaladores y comprimidos | No descarga ni analiza el archivo |
| Acción financiera | Pagos interoperables y criptomonedas | No confirma beneficiario, monto económico o autorización |
| Secreto efímero | OTP y campos sensibles | No valida vigencia ni evita que otra app lo use |
| Carga opaca | Contenido binario no interpretable | Opacidad no equivale a malicia |

La condición exacta, peso, confianza y falso positivo de cada id está en
[`rootcause/HEURISTICS.md`](rootcause/HEURISTICS.md).

## Acciones deliberadamente separadas

- **Permitir**: la carga es entregable y no requiere una barrera adicional por
  reglas locales.
- **Confirmar**: la carga es interpretable, pero una señal exige decisión humana.
- **Solo inspeccionar**: el contenido merece análisis sin entrega inmediata.
- **Bloquear URI ambigua**: no puede construirse una entrega externa inequívoca.

Bloquear no significa “malicioso”; significa que el sistema no puede delegar la
acción de forma segura. Permitir no significa “seguro”; significa que no existe
un bloqueo local aplicable.

## Correlación

Una investigación puede combinar el hash y el instante de la evidencia con
RootCause Web o Mobile. En 0.1.0 esa correlación es manual y por exportación; no
existe envío automático entre productos.
