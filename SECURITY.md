# Política de seguridad

## Versiones con soporte

Mientras el proyecto permanezca en la serie `0.1.x`, solo la revisión más
reciente de esa serie recibe correcciones de seguridad. El repositorio es una
herramienta de investigación en desarrollo y no sustituye un antivirus, EDR,
servicio de reputación ni validación independiente del destinatario.

## Reportar una vulnerabilidad

Usa el botón **Report a vulnerability** de
[GitHub Security Advisories](https://github.com/vladimiracunadev-create/rootcause-qr-inspector/security/advisories/new).
No abras un issue público para una vulnerabilidad que todavía pueda explotarse.

Incluye únicamente:

- versión o commit afectado y plataforma;
- impacto esperado y pasos mínimos de reproducción;
- un QR sintético o una carga redactada;
- logs sin secretos ni datos personales, si son imprescindibles.

No envíes OTP, contraseñas Wi-Fi, semillas, claves privadas, documentos de
identidad, URLs firmadas ni datos de pago reales. El proyecto no ofrece un SLA
formal; se acusará recibo y se coordinará la divulgación tan pronto como sea
posible según la severidad y la reproducibilidad.

## Modelo y controles

El alcance técnico, el modelo de amenazas y el plan de pruebas están en:

- [`docs/SECURITY.md`](docs/SECURITY.md);
- [`docs/security/THREAT_MODEL.md`](docs/security/THREAT_MODEL.md);
- [`docs/security/SECURITY_TEST_PLAN.md`](docs/security/SECURITY_TEST_PLAN.md);
- [`docs/security/MASVS_CHECKLIST.md`](docs/security/MASVS_CHECKLIST.md).

Una lectura sin hallazgos locales no demuestra que el destino sea seguro.
