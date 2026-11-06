# Política de dependencias

> Vigente desde 0.2.0. Nace de un hecho del propio historial: en 0.1.4 se
> aceptaron tres bumps de Dependabot y después se revirtieron en bloque
> (`revert: keep the v0.1.4 dependency baseline`) para no mover la base de un
> release ya publicado. Esa decisión fue correcta y no estaba escrita en
> ninguna parte, así que volvía a discutirse en cada bump.

## Las versiones se fijan exactas

`pubspec.yaml` fija versiones exactas, no rangos. Un rango convierte cada
`pub get` en una resolución distinta, y este producto declara en su evidencia
qué analizó: dos ejecuciones con el mismo número de versión tienen que llevar
el mismo código dentro. `pubspec.lock` se versiona y la CI comprueba que
exista.

## Qué se sube y qué no

| Cambio | Decisión | Por qué |
|---|---|---|
| Parche (`x.y.Z`) | **se sube** en la entrega siguiente | son correcciones; no moverlas es acumular deuda sin obtener nada |
| Menor (`x.Y.z`) de un paquete cuyo comportamiento cubren las pruebas | **se sube** | la suite y el análisis estricto responden por él |
| Menor de un plugin que solo un dispositivo puede validar | **se declara y se espera** a una ventana con prueba física | cámara, rasterizado de PDF y biometría no se comprueban en CI: un verde aquí no dice nada sobre ellos |
| Mayor (`X.y.z`), y cualquier `0.y.z` que suba `y` | **se evalúa como tarea aparte**, con su propia entrega | son rupturas por convención; mezclarlas con funcionalidad impide saber qué rompió qué |
| Cualquier bump que exija un SDK de Flutter más nuevo que el fijado | **se rechaza** | `web 1.1.2` pide Flutter 3.47.9 y el proyecto fija 3.44.7. La versión del SDK se cambia por decisión propia, no arrastrada por una dependencia |

## La cadena de compilación también se fija

No basta con fijar las dependencias de Dart. En 0.2.0, la CI dejó de poder
compilar Android sin que cambiara una línea del proyecto: el runner de GitHub
pasó a un JDK 25 y Gradle 8.14.3 con AGP 8.11.1 no lo soportan. El error fue un
mensaje de Gradle que era solo la versión, `25.0.5`.

| Pieza | Dónde se fija |
|---|---|
| Flutter | `FLUTTER_VERSION` en los dos workflows y `environment` de `pubspec.yaml` |
| JDK | `actions/setup-java` con Temurin 21 en los dos workflows |
| Gradle | `GRADLE_DISTRIBUTION` en `tool/bootstrap.py` |
| Android Gradle Plugin y Kotlin | `ANDROID_GRADLE_PLUGIN` y `KOTLIN_GRADLE_PLUGIN` en `tool/bootstrap.py` |
| `compileSdk` y `minSdk` | parcheados por `tool/bootstrap.py` sobre la plantilla generada |

La regla: **si una pieza de la cadena no está fijada, el día que el runner
cambie no habrá cambiado nada en el repositorio y aun así el release no saldrá.**
Un build verde en la máquina de desarrollo no responde por la CI, porque el JDK
local es otro.

## Lo que subió en 0.2.0

`crypto`, `flutter_secure_storage`, `image_picker`, `sembast`, `sembast_web`,
`share_plus`, `shared_preferences` y `url_launcher`.

## Lo que quedó fuera en 0.2.0, y por qué

| Paquete | De → a | Motivo |
|---|---|---|
| `mobile_scanner` | 7.4.0 → 7.5.0 | es la cámara. Un cambio menor aquí afecta a enfoque, resolución y detección, y nada de eso se comprueba sin un teléfono. Espera la ventana de prueba física |
| `pdfrx` | 2.4.5 → 2.12.0 | ocho versiones menores del rasterizador, justo después de que 0.1.4 corrigiera la política de resolución para QR pequeños. Se sube con fixtures de PDF ejecutados en dispositivo |
| `cross_file` | 0.3.5+4 → 0.4.0 | antes de 1.0, subir la menor es ruptura por convención |
| `cupertino_icons` | 1.0.9 → 2.0.0 | mayor |
| `file_picker` | 12.0.0 → 13.3.2 | mayor |
| `web` | 1.1.1 → 1.1.2 | exige Flutter 3.47.9 |

## Cómo se sube una dependencia

1. editar el pin en `pubspec.yaml`;
2. `flutter pub get` y versionar el `pubspec.lock` resultante;
3. `dart format --output=none --set-exit-if-changed lib test tool`;
4. `flutter analyze --fatal-infos`;
5. `flutter test`;
6. `python tool/verify_rootcause_contract.py`;
7. `flutter build apk --release` y `flutter build web --release`;
8. anotar en el `CHANGELOG` qué subió y qué quedó fuera con su motivo.

Un bump sin el paso 8 es indistinguible de un bump accidental seis meses
después.
