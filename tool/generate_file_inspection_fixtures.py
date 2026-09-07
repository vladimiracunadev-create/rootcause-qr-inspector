#!/usr/bin/env python3
"""Generate synthetic local fixtures for native file-code inspection tests."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

import qrcode
from PIL import Image, ImageDraw
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "test_assets" / "file_inspection"

PAYLOAD_NORMAL = "https://normal.example"
PAYLOAD_CONFUSING = "https://trusted.example@evil.example/login"
PAYLOAD_EMAIL = "mailto:person@example.com?subject=Synthetic"
PAYLOAD_WIFI = "WIFI:T:WPA;S:Laboratorio;P:synthetic-password;;"


def qr_image(payload: str, box_size: int = 10) -> Image.Image:
    code = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=box_size,
        border=4,
    )
    code.add_data(payload)
    code.make(fit=True)
    return code.make_image(fill_color="black", back_color="white").convert("RGB")


def save_multiple(path: Path) -> None:
    items = [
        ("Web", qr_image(PAYLOAD_NORMAL, 7)),
        ("Mail", qr_image(PAYLOAD_EMAIL, 7)),
        ("Wi-Fi", qr_image(PAYLOAD_WIFI, 7)),
    ]
    width = sum(image.width for _, image in items) + 80 * (len(items) + 1)
    height = max(image.height for _, image in items) + 150
    sheet = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(sheet)
    x = 80
    for label, image in items:
        sheet.paste(image, (x, 70))
        draw.text((x, 25), label, fill="black")
        x += image.width + 80
    sheet.save(path, optimize=True)


def save_no_code(path: Path) -> None:
    image = Image.new("RGB", (1200, 800), "white")
    draw = ImageDraw.Draw(image)
    draw.rectangle((80, 80, 1120, 720), outline="#087A6D", width=8)
    draw.text((250, 360), "Synthetic fixture without a code", fill="#112B27")
    image.save(path, optimize=True)


def save_document(path: Path) -> None:
    page_width, page_height = A4
    with tempfile.TemporaryDirectory(prefix="rcqr-fixtures-") as directory:
        temp = Path(directory)
        payloads = {
            1: (PAYLOAD_NORMAL, "Synthetic web destination"),
            3: (PAYLOAD_CONFUSING, "Synthetic userinfo host-confusion case"),
            5: (PAYLOAD_WIFI, "Synthetic Wi-Fi configuration"),
        }
        pdf = canvas.Canvas(str(path), pagesize=A4, pageCompression=1)
        pdf.setTitle("RootCause QR Inspector synthetic fixture")
        pdf.setAuthor("RootCause QR Inspector tests")
        for page_number in range(1, 6):
            pdf.setFont("Helvetica-Bold", 18)
            pdf.drawString(24 * mm, page_height - 28 * mm, f"File inspection fixture - page {page_number}")
            if page_number in payloads:
                payload, label = payloads[page_number]
                qr_path = temp / f"page-{page_number}.png"
                qr_image(payload, 10).save(qr_path)
                pdf.setFont("Helvetica", 11)
                pdf.drawString(24 * mm, page_height - 42 * mm, label)
                pdf.drawImage(
                    str(qr_path),
                    45 * mm,
                    80 * mm,
                    width=120 * mm,
                    height=120 * mm,
                    preserveAspectRatio=True,
                    mask="auto",
                )
            else:
                pdf.setFont("Helvetica", 12)
                pdf.drawString(24 * mm, page_height - 48 * mm, "This page intentionally contains no code.")
            pdf.setFont("Helvetica", 9)
            pdf.drawCentredString(page_width / 2, 16 * mm, f"Synthetic test data - {page_number}/5")
            pdf.showPage()
        pdf.save()


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    qr_image(PAYLOAD_NORMAL).save(OUTPUT / "fixture_single_url.png", optimize=True)
    save_multiple(OUTPUT / "fixture_multiple_codes.png")
    save_no_code(OUTPUT / "fixture_no_code.png")
    save_document(OUTPUT / "fixture_document.pdf")
    manifest = {
        "schema": "rootcause.file-inspection-fixtures.v1",
        "syntheticOnly": True,
        "files": [
            {"file": "fixture_single_url.png", "expectedPayloads": [PAYLOAD_NORMAL]},
            {
                "file": "fixture_multiple_codes.png",
                "expectedPayloads": [PAYLOAD_NORMAL, PAYLOAD_EMAIL, PAYLOAD_WIFI],
            },
            {"file": "fixture_no_code.png", "expectedPayloads": []},
            {
                "file": "fixture_document.pdf",
                "pages": 5,
                "expectedByPage": {
                    "1": [PAYLOAD_NORMAL],
                    "2": [],
                    "3": [PAYLOAD_CONFUSING],
                    "4": [],
                    "5": [PAYLOAD_WIFI],
                },
            },
        ],
    }
    (OUTPUT / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
