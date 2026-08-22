# Landing de GitHub Pages

Sitio estático de RootCause QR Inspector. El workflow
[`deploy-landing.yml`](../.github/workflows/deploy-landing.yml) publica:

| Ruta | Origen |
|---|---|
| `/` | contenido de `landing/` |
| `/assets/icon-512.png` | icono versionado en `assets/launcher/web/` |
| `/assets/capturas/` | capturas versionadas en `docs/images/capturas/` |
| `/app/` | demo técnica producida con `flutter build web --release` |

Para revisar la landing sin compilar Flutter:

```bash
mkdir -p /tmp/rootcause-qr-site/assets
cp -r landing/. /tmp/rootcause-qr-site/
cp assets/launcher/web/Icon-512.png /tmp/rootcause-qr-site/assets/icon-512.png
cp -r docs/images/capturas /tmp/rootcause-qr-site/assets/capturas
python3 -m http.server 8000 --directory /tmp/rootcause-qr-site
```

La ruta `/app/` solo existe después de construir la demo web. No es una
plataforma soportada del producto. Para revisar esa demo, usar
`flutter run -d chrome`; las aplicaciones objetivo son Android e iOS.
