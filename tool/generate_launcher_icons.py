#!/usr/bin/env python3
"""Draw the application icon and export every size the platforms need.

The icon is generated from code instead of being stored as a single opaque
binary, so the geometry stays reviewable and reproducible. Run it after
changing the design; the resulting PNG files under `assets/launcher/` are
versioned and `tool/bootstrap.py` copies them into the generated native
projects.

Requires Pillow. It is not needed to build the application, only to redraw the
icon:

    python3 -m pip install pillow
    python3 tool/generate_launcher_icons.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "launcher"

CANVAS = 1024
BACKGROUND = (4, 16, 14)
BACKGROUND_LIGHT = (0, 111, 98)
GLYPH = (236, 255, 250)
ACCENT = (67, 224, 196)
WARNING = (255, 197, 110)

# Legacy launcher icons are masked by the launcher itself; adaptive icons split
# the drawing into a full-bleed background and a foreground that must stay
# inside the central safe zone.
ANDROID_LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ANDROID_ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
WEB_SIZES = {"Icon-192.png": 192, "Icon-512.png": 512, "Icon-maskable-192.png": 192, "Icon-maskable-512.png": 512}
IOS_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}
MACOS_SIZES = {f"app_icon_{size}.png": size for size in (16, 32, 64, 128, 256, 512, 1024)}


def rounded_background(size: int) -> Image.Image:
    """Vertical two-tone teal panel with rounded corners."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gradient = Image.new("RGBA", (1, size))
    for y in range(size):
        ratio = y / max(size - 1, 1)
        gradient.putpixel(
            (0, y),
            tuple(
                int(BACKGROUND_LIGHT[channel] + (BACKGROUND[channel] - BACKGROUND_LIGHT[channel]) * ratio)
                for channel in range(3)
            )
            + (255,),
        )
    gradient = gradient.resize((size, size))

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
    image.paste(gradient, (0, 0), mask)
    return image


def draw_glyph(draw: ImageDraw.ImageDraw, size: int, scale: float) -> None:
    """Security shield containing a compact QR inspection signal.

    `scale` is the fraction of the canvas the drawing may occupy. Adaptive
    foregrounds need a smaller value so nothing is clipped by the launcher mask.
    """
    side = size * scale
    left = (size - side) / 2
    top = (size - side) / 2
    centre = size / 2

    # The shield is the primary silhouette: the product protects the decision,
    # not merely the act of reading pixels.
    shield = [
        (centre, top),
        (left + side * 0.88, top + side * 0.14),
        (left + side * 0.82, top + side * 0.62),
        (left + side * 0.70, top + side * 0.82),
        (centre, top + side),
        (left + side * 0.30, top + side * 0.82),
        (left + side * 0.18, top + side * 0.62),
        (left + side * 0.12, top + side * 0.14),
    ]
    draw.polygon(shield, fill=GLYPH)

    # Dark QR modules inside the shield remain legible at launcher sizes.
    module = side * 0.105
    gap = side * 0.04
    qr_left = centre - module * 1.5 - gap
    qr_top = top + side * 0.28
    dark = BACKGROUND
    for row, column in ((0, 0), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (2, 2)):
        x = qr_left + column * (module + gap)
        y = qr_top + row * (module + gap)
        draw.rounded_rectangle((x, y, x + module, y + module), radius=module * 0.22, fill=dark)
    dot = module * 0.46
    draw.rounded_rectangle(
        (centre - dot / 2, qr_top + module * 0.27, centre + dot / 2, qr_top + module * 0.27 + dot),
        radius=dot * 0.25,
        fill=WARNING,
    )

    # The analysis line crosses the evidence, never the entire icon frame.
    line_half = side * 0.30
    line_height = max(side * 0.022, 1)
    draw.rounded_rectangle(
        (centre - line_half, top + side * 0.61, centre + line_half, top + side * 0.61 + line_height * 2),
        radius=line_height,
        fill=ACCENT,
    )


def full_icon(size: int) -> Image.Image:
    image = rounded_background(size)
    draw_glyph(ImageDraw.Draw(image), size, scale=0.62)
    return image


def maskable_icon(size: int) -> Image.Image:
    """Full-bleed variant: launchers may crop up to the outer 20 %."""
    image = Image.new("RGBA", (size, size), BACKGROUND + (255,))
    gradient = rounded_background(size * 2).resize((size, size))
    image.paste(gradient, (0, 0))
    flat = Image.new("RGBA", (size, size), BACKGROUND + (255,))
    flat.paste(image, (0, 0), image)
    draw_glyph(ImageDraw.Draw(flat), size, scale=0.48)
    return flat


def store_icon(size: int) -> Image.Image:
    """Opaque full-bleed icon for Apple stores; the OS applies its own mask."""
    image = Image.new("RGBA", (size, size), BACKGROUND + (255,))
    image.paste(rounded_background(size), (0, 0), rounded_background(size))
    draw_glyph(ImageDraw.Draw(image), size, scale=0.62)
    return image


def adaptive_foreground(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_glyph(ImageDraw.Draw(image), size, scale=0.46)
    return image


def save(image: Image.Image, relative: str) -> None:
    path = OUTPUT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)
    print(path.relative_to(ROOT))


def main() -> None:
    master = full_icon(CANVAS)
    save(master, "icon-1024.png")

    for density, size in ANDROID_LEGACY.items():
        save(full_icon(CANVAS).resize((size, size), Image.LANCZOS), f"android/mipmap-{density}/ic_launcher.png")
    for density, size in ANDROID_ADAPTIVE.items():
        save(
            adaptive_foreground(CANVAS).resize((size, size), Image.LANCZOS),
            f"android/mipmap-{density}/ic_launcher_foreground.png",
        )

    for name, size in WEB_SIZES.items():
        source = maskable_icon(CANVAS) if "maskable" in name else full_icon(CANVAS)
        save(source.resize((size, size), Image.LANCZOS), f"web/{name}")
    save(full_icon(CANVAS).resize((32, 32), Image.LANCZOS), "web/favicon.png")

    for name, size in IOS_SIZES.items():
        save(store_icon(CANVAS).resize((size, size), Image.LANCZOS), f"ios/{name}")
    for name, size in MACOS_SIZES.items():
        save(store_icon(CANVAS).resize((size, size), Image.LANCZOS), f"macos/{name}")


if __name__ == "__main__":
    main()
