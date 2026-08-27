# Documentación de sistema · RootCause QR Inspector

Portada e índice de la documentación técnica, funcional, arquitectónica y
operativa del repositorio. Se escribió recorriendo el código fuente completo, no
resumiendo la documentación existente: cada afirmación apunta a un archivo, una
función, una prueba o un comando concreto de este repositorio.

## El sistema en una frase

RootCause QR Inspector es una **aplicación móvil Flutter que inspecciona códigos
QR y de barras en el propio dispositivo**, explica qué observó antes de permitir
cualquier acción y permite exportar esa observación como evidencia verificable.
No consulta ningún servidor.

## Para quién es esta documentación

| Perfil | Empieza por | Después |
|---|---|---|
| Persona no técnica | [Descripción general](01-system-overview.md) | [Resumen ejecutivo](17-executive-summary.md) |
| Desarrollador que se incorpora | [Guía para nuevos desarrolladores](18-new-developer-guide.md) | [Instalación](02-installation-and-execution.md) → [Arquitectura](03-architecture.md) → [Mapa del código](04-code-map.md) |
| Desarrollador con experiencia | [Referencia técnica](05-technical-reference.md) | [Explicación profunda](06-deep-code-explanation.md) |
| Auditor técnico o de seguridad | [Arquitectura](03-architecture.md) | [Seguridad](11-security.md) → [Riesgos y deuda técnica](15-risks-and-technical-debt.md) → [Trazabilidad](19-traceability-matrix.md) |
| Operación y soporte | [Despliegue y operación](13-deployment-and-operations.md) | [Solución de problemas](14-troubleshooting.md) |
| Otro agente de IA | [Mapa del código](04-code-map.md) | [Referencia técnica](05-technical-reference.md) + [Trazabilidad](19-traceability-matrix.md) |

## Tabla de contenidos

| # | Documento | Contenido | Estado |
|---|---|---|---|
| 01 | [Descripción general del sistema](01-system-overview.md) | Qué es, qué problema resuelve, actores, flujo, tecnologías y límites | Completo |
| 02 | [Instalación y ejecución](02-installation-and-execution.md) | Requisitos, dependencias, generación de plataformas, ejecución y pruebas | Completo |
| 03 | [Arquitectura](03-architecture.md) | Capas, patrones, diagramas, estado, errores, persistencia y seguridad | Completo |
| 04 | [Mapa completo del código](04-code-map.md) | Inventario jerárquico de directorios, archivos, clases y funciones | Completo |
| 05 | [Referencia técnica](05-technical-reference.md) | Catálogo de constantes, tipos, funciones, claves, rutas y códigos de error | Completo |
| 06 | [Explicación profunda del código](06-deep-code-explanation.md) | Flujo interno, decisiones y casos límite de los módulos importantes | Completo |
| 07 | [Base de datos](07-database.md) | Motor, almacenes, diccionario de datos, migraciones y cifrado | Completo |
| 08 | [Flujo de datos](08-data-flow.md) | Origen, validación, transformación, almacenamiento y salida de cada dato | Completo |
| 09 | [APIs e integraciones](09-apis-and-integrations.md) | Contratos JSON, interfaces de plataforma y ausencia deliberada de red | Completo |
| 10 | [Configuración](10-configuration.md) | Preferencias, política de análisis, banderas y consecuencias de cada valor | Completo |
| 11 | [Seguridad](11-security.md) | Autenticación, cifrado, validación de entrada y superficie de ataque | Completo |
| 12 | [Pruebas y calidad](12-testing-and-quality.md) | Suite existente, cobertura observable, huecos y propuesta priorizada | Completo |
| 13 | [Despliegue y operación](13-deployment-and-operations.md) | CI/CD, artefactos, publicación, mantenimiento y reversión | Completo |
| 14 | [Solución de problemas](14-troubleshooting.md) | Síntoma, causa, diagnóstico, solución y riesgo | Completo |
| 15 | [Riesgos y deuda técnica](15-risks-and-technical-debt.md) | Hallazgos clasificados por severidad, impacto, evidencia y prioridad | Completo · informativo |
| 16 | [Glosario](16-glossary.md) | Términos técnicos, del dominio y del producto | Completo |
| 17 | [Resumen ejecutivo](17-executive-summary.md) | Presentación para decisión, sin detalle innecesario | Completo |
| 18 | [Guía para nuevos desarrolladores](18-new-developer-guide.md) | Itinerario, entorno, convenciones y primeras tareas | Completo |
| 19 | [Matriz de trazabilidad](19-traceability-matrix.md) | De la funcionalidad al código, a los datos y a su prueba | Completo |

Los mismos documentos en PDF están en [`pdf/`](pdf/). Se generan desde estos
Markdown con `python tool/build_system_documentation_pdf.py`; el procedimiento
está en [13-deployment-and-operations.md](13-deployment-and-operations.md).

## Datos del análisis

| Dato | Valor |
|---|---|
| Fecha del análisis | 26 de agosto de 2026 |
| Versión analizada | 0.1.1+2 |
| Commit analizado | `4d1ba4b` |
| Archivos Dart en `lib/` | 65 |
| Archivos de prueba Dart | 24 |
| Casos de prueba declarados | 88 (87 los ejecuta `flutter test`) |
| Herramientas en `tool/` | 13 |
| Reglas del motor de análisis | 26 |

## Convenciones

Estos marcadores aparecen a lo largo de los documentos y significan siempre lo
mismo:

| Marcador | Significado |
|---|---|
| **Comprobado** | Se leyó el código, se ejecutó el comando o se verificó el archivo en este repositorio |
| **Inferencia** | Conclusión razonada a partir del código, no una afirmación del propio repositorio |
| **No identificado** | Se buscó y no existe en el repositorio |
| **No documentado en el repositorio** | Existe en el código pero no lo explica la documentación previa |
| **Requiere validación** | Solo puede confirmarse con hardware, red o credenciales que este análisis no tiene |

Otras convenciones:

- las rutas se escriben relativas a la raíz del repositorio;
- los nombres de clases, funciones, almacenes y claves se conservan **literales**,
  para que puedan buscarse con `grep`;
- ningún ejemplo contiene secretos, credenciales ni datos personales reales; se
  usan dominios reservados (`example.com`, `*.example`) y valores ficticios;
- los diagramas Mermaid siempre van acompañados de una explicación en texto: el
  diagrama nunca es el único portador de la información.

## Pendiente de validar

Lo que esta documentación **no** pudo comprobar en el entorno de análisis:

1. **Ejecución de Flutter.** Flutter y Dart no están instalados en la máquina
   donde se escribió esta documentación. `flutter analyze`, `flutter test` y las
   compilaciones no se ejecutaron localmente; la evidencia proviene de la CI
   pública del repositorio. Ver [12-testing-and-quality.md](12-testing-and-quality.md).
2. **Comportamiento en dispositivo físico.** Cámara, biometría, almacén seguro,
   ciclo de vida y apertura de aplicaciones externas solo pueden confirmarse en
   un teléfono real. Ver [`../quality/DEVICE_TEST_MATRIX.md`](../quality/DEVICE_TEST_MATRIX.md).
3. **La corrección de lectura de 0.1.1.** Alcance de la cámara con un código
   lejano, confirmación audible y conteo de unidades repetidas.
4. **Carpetas nativas.** `android/`, `ios/` y `web/` no están versionadas: las
   genera `tool/bootstrap.py`. Lo que este análisis describe de ellas proviene
   de leer ese generador, no de inspeccionar el resultado.

## Relación con la documentación previa

Este directorio **no sustituye** la documentación existente del repositorio; la
complementa y la enlaza. La documentación previa está organizada por audiencia y
tema en [`../INDEX.md`](../INDEX.md), y sigue siendo la fuente normativa en tres
áreas concretas:

| Área | Fuente normativa |
|---|---|
| Especificación de las 26 reglas | [`../rootcause/HEURISTICS.md`](../rootcause/HEURISTICS.md) |
| Contrato de evidencia exportable | [`../../schemas/rootcause-qr-evidence.schema.json`](../../schemas/rootcause-qr-evidence.schema.json) |
| Compromisos que no pueden romperse | [`../quality/COMPATIBILITY_CONTRACT.md`](../quality/COMPATIBILITY_CONTRACT.md) |
