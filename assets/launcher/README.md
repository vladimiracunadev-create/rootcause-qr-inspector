# Iconos de la aplicación

Estos PNG **no son recursos de ejecución** y por eso no se declaran en la
sección `flutter: assets:` de `pubspec.yaml`: empaquetarlos dentro de la
aplicación solo aumentaría su tamaño sin que ningún widget los use. Son
entradas de compilación que `tool/bootstrap.py` copia a los proyectos nativos
generados.

| Ruta | Destino |
|---|---|
| `android/mipmap-*/ic_launcher.png` | Icono heredado de Android, cinco densidades |
| `android/mipmap-*/ic_launcher_foreground.png` | Capa frontal del icono adaptativo y del monocromo |
| `web/Icon-*.png` | Iconos de la demo web, incluidas las variantes *maskable* |
| `web/favicon.png` | Favicon del sitio |
| `ios/Icon-App-*.png` | AppIcon completo para iPhone, iPad y App Store |
| `icon-1024.png` | Maestro para documentación, landing y fichas futuras |

La silueta combina un **escudo**, módulos QR y una línea de análisis. Así el
icono comunica la función de seguridad del producto incluso sin texto y deja
de parecer el de un lector genérico.

## Cómo regenerarlos

El diseño vive en código, no en un binario opaco, para que la geometría sea
revisable en una revisión de cambios:

```bash
uv run --with pillow python tool/generate_launcher_icons.py
```

Pillow solo hace falta para redibujar el icono. Compilar la aplicación no lo
requiere, y por eso la CI no lo instala.
