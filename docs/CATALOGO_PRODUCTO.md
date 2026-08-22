# Catálogo de producto: RootCause QR Inspector

Este documento es la fuente de verdad para comunicar esta edición. Si una
landing, descripción o release promete más, prevalecen aquí los límites.

## Identidad

| Campo | Definición |
|---|---|
| Producto | RootCause QR Inspector |
| Versión | 0.1.0 |
| Superficie | Cargas QR y otros códigos 1D/2D antes de entregarlos a otra app |
| Tecnología | Flutter y Dart; Android, iOS, macOS y PWA |
| Modelo | Análisis local determinista con 26 reglas identificables |
| Evidencia | `rootcause.evidence.qr.v1`, redactada por defecto y con checksum SHA-256 |
| Persistencia | Historial e inventarios locales cifrados con AES-256-GCM |
| Privacidad | Sin cuenta, publicidad, analítica ni telemetría |
| Licencia | MIT, coherente con la procedencia en Universal Code Scanner |

## Problema que resuelve

Un código impreso oculta una instrucción. La cámara ve módulos; la persona no ve
el host, un `userinfo` engañoso, el cambio de dominio dentro de una redirección,
un instalador ni el beneficiario hasta después de interpretar la carga.

Esta edición crea una pausa verificable entre **capturar** y **actuar**:

1. interpreta la carga;
2. registra hechos locales;
3. aplica reglas con ids estables;
4. deriva hipótesis separadas;
5. decide si permite, exige confirmación, limita a inspección o bloquea una URI
   que no puede entregar con seguridad.

## A quién sirve

| Perfil | Uso principal |
|---|---|
| Persona que recibe un QR | Ver el destino y sus señales antes de abrirlo |
| Soporte o respuesta a incidentes | Exportar evidencia mínima y correlacionable |
| Comercio o inventario | Contar códigos localmente sin convertirlos en telemetría |
| Integrador | Inyectar política de marcas y consumir el contrato JSON |
| Docencia de seguridad | Mostrar la diferencia entre hecho, hipótesis y veredicto |

## Qué no es

- no es antivirus, EDR ni navegador aislado;
- no consulta reputación, DNS, certificados, edad o dueño de dominio;
- no confirma identidad física, comercio ni beneficiario;
- no convierte un puntaje en probabilidad de fraude;
- no ejecuta una respuesta automática ni declara “sitio seguro”.

## Relación con Universal Code Scanner

Universal Code Scanner aporta captura, parsers, historial, inventario,
generación, importación y cifrado. RootCause QR Inspector conserva ese sustrato
y añade el contrato de investigación: observación → hallazgo → hipótesis →
decisión → evidencia. La matriz exacta está en
[`rootcause/ADOPTION_MATRIX.md`](rootcause/ADOPTION_MATRIX.md).

## Reglas de comunicación

- El QR es la superficie; phishing es una hipótesis posible.
- “Sin señales locales” nunca se traduce como “seguro”.
- El checksum aporta integridad comprobable, no autoría ni autenticación.
- PWA y builds de CI no se presentan como binarios firmados de release.
- Una capacidad de otra edición RootCause no se atribuye a este sensor.
