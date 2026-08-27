#!/usr/bin/env python3
"""Genera los PDF de `docs/system-documentation/` desde sus Markdown.

Produce un PDF por documento y uno consolidado, todos en
`docs/system-documentation/pdf/`. El Markdown es la única fuente: este script no
mantiene una segunda versión del texto.

Capas y degradación
-------------------
- `markdown` y `xhtml2pdf` son **obligatorios**. Sin ellos el script se detiene
  con la instrucción de instalación.
- `mmdc` (`@mermaid-js/mermaid-cli`) es **opcional**. Convierte los bloques
  ```mermaid``` a PNG. Si no está, el diagrama se incluye como bloque de texto y
  se avisa por consola, en vez de fallar: un PDF con un diagrama en texto es
  mejor que ningún PDF.

Los diagramas se cachean por hash de su contenido en `pdf/.mermaid-cache/`, así
que una segunda ejecución solo vuelve a renderizar lo que cambió.

Uso
---
    python tool/build_system_documentation_pdf.py
    python tool/build_system_documentation_pdf.py --only 03-architecture.md
    python tool/build_system_documentation_pdf.py --skip-combined
"""
from __future__ import annotations

import argparse
import hashlib
import html
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "system-documentation"
OUTPUT = SOURCE / "pdf"
CACHE = OUTPUT / ".mermaid-cache"

PRODUCT = "RootCause QR Inspector"

# xhtml2pdf soporta un subconjunto de CSS: nada de flexbox ni grid. El diseño se
# apoya en bloques, tablas con ancho fijo y saltos de página explícitos.
STYLESHEET = """
@page {
  size: a4 portrait;
  margin: 2.0cm 1.8cm 2.2cm 1.8cm;
  @frame footer_frame { -pdf-frame-content: footer_content; bottom: 1.0cm; margin-left: 1.8cm; margin-right: 1.8cm; height: 1cm; }
}
body { font-family: Helvetica, Arial, sans-serif; font-size: 9.5pt; line-height: 1.45; color: #14201d; }
h1 { font-size: 19pt; color: #00504a; margin: 0 0 4pt 0; -pdf-outline: true; -pdf-outline-level: 0; }
h2 { font-size: 13pt; color: #00504a; margin: 16pt 0 5pt 0; border-bottom: 0.7pt solid #b9cfca; padding-bottom: 2pt; -pdf-outline: true; -pdf-outline-level: 1; }
h3 { font-size: 11pt; color: #1c4a45; margin: 12pt 0 4pt 0; -pdf-outline: true; -pdf-outline-level: 2; }
h4 { font-size: 10pt; color: #1c4a45; margin: 10pt 0 3pt 0; }
p { margin: 0 0 6pt 0; }
ul, ol { margin: 0 0 6pt 14pt; }
li { margin-bottom: 2pt; }
a { color: #00695f; text-decoration: none; }
code { font-family: Courier, monospace; font-size: 8.5pt; background-color: #eef3f2; }
pre { font-family: Courier, monospace; font-size: 7.8pt; background-color: #f2f6f5;
      border: 0.5pt solid #cfdedb; padding: 5pt; margin: 0 0 8pt 0; line-height: 1.25; }
table { width: 100%; border-collapse: collapse; margin: 0 0 9pt 0; font-size: 8pt; }
th { background-color: #dcebe8; border: 0.5pt solid #a9c4bf; padding: 3pt 4pt; text-align: left; font-weight: bold; }
td { border: 0.5pt solid #c6d8d5; padding: 3pt 4pt; vertical-align: top; }
blockquote { margin: 0 0 8pt 0; padding: 5pt 8pt; background-color: #f4f8f7; border-left: 2.5pt solid #00897b; }
hr { border: 0; border-top: 0.5pt solid #c6d8d5; margin: 10pt 0; }
img { }
.cover { padding-top: 2.2cm; }
.cover-kicker { font-size: 10pt; color: #00695f; letter-spacing: 1.5pt; }
.cover-title { font-size: 24pt; color: #00332f; margin: 8pt 0 4pt 0; }
.cover-meta { font-size: 9.5pt; color: #486661; margin-top: 16pt; }
.cover-note { font-size: 8.5pt; color: #6b8582; margin-top: 10pt; }
.toc { font-size: 9pt; }
.toc-entry { margin-bottom: 3pt; }
.footer { font-size: 7.5pt; color: #7b918e; }
.mermaid-fallback { font-size: 7.5pt; color: #4a625e; }
"""


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_dependencies():
    try:
        import markdown  # noqa: F401
    except ImportError:
        fail("Falta el paquete `markdown`. Instálalo con: pip install markdown")
    try:
        from xhtml2pdf import pisa  # noqa: F401
    except ImportError:
        fail("Falta el paquete `xhtml2pdf`. Instálalo con: pip install xhtml2pdf")
    import markdown as md
    from xhtml2pdf import pisa

    return md, pisa


def mermaid_binary() -> str | None:
    """Devuelve el ejecutable de mermaid-cli, o None si no está instalado."""
    return shutil.which("mmdc")


def render_mermaid(code: str, binary: str) -> Path | None:
    """Renderiza un diagrama a PNG, con caché por hash del contenido."""
    CACHE.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256(code.encode("utf-8")).hexdigest()[:20]
    target = CACHE / f"{digest}.png"
    if target.exists():
        return target
    source = CACHE / f"{digest}.mmd"
    source.write_text(code, encoding="utf-8", newline="\n")
    try:
        subprocess.run(
            [binary, "-i", str(source), "-o", str(target), "-b", "white", "-w", "1400"],
            check=True,
            capture_output=True,
            timeout=180,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
        print(f"  aviso: mmdc no pudo renderizar un diagrama ({type(exc).__name__})")
        return None
    return target if target.exists() else None


MERMAID_BLOCK = re.compile(r"^```mermaid[ \t]*\n(.*?)^```[ \t]*$", re.MULTILINE | re.DOTALL)


def replace_mermaid(text: str, binary: str | None, stats: dict) -> str:
    """Sustituye los fences mermaid por una imagen, o los deja como texto."""

    def substitute(match: re.Match) -> str:
        code = match.group(1)
        if binary is not None:
            image = render_mermaid(code, binary)
            if image is not None:
                stats["rendered"] += 1
                # Marcador propio: el conversor Markdown no debe tocarlo.
                return f"\n@@DIAGRAM:{image.as_posix()}@@\n"
        stats["fallback"] += 1
        return "```text\n" + code + "```"

    return MERMAID_BLOCK.sub(substitute, text)


DIAGRAM_MARKER = re.compile(r"<p>@@DIAGRAM:(.+?)@@</p>")


def restore_diagrams(body: str) -> str:
    return DIAGRAM_MARKER.sub(
        lambda m: f'<div><img src="{html.escape(m.group(1))}" style="width: 15.5cm;" /></div>',
        body,
    )


def strip_md_links(text: str) -> str:
    """Convierte `[texto](destino)` en `texto` para índices y títulos."""
    return re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)


def document_title(text: str, fallback: str) -> str:
    for line in text.splitlines():
        if line.startswith("# "):
            return strip_md_links(line[2:].strip())
    return fallback


def section_titles(text: str) -> list[str]:
    return [
        strip_md_links(line[3:].strip())
        for line in text.splitlines()
        if line.startswith("## ")
    ]


def cover(title: str, subtitle: str, version: str, commit: str, today: str) -> str:
    return f"""
<div class="cover">
  <div class="cover-kicker">{html.escape(PRODUCT.upper())}</div>
  <div class="cover-title">{html.escape(title)}</div>
  <p>{html.escape(subtitle)}</p>
  <div class="cover-meta">
    Versión analizada: <b>{html.escape(version)}</b><br />
    Commit: <b>{html.escape(commit)}</b><br />
    Fecha del documento: <b>{html.escape(today)}</b>
  </div>
  <div class="cover-note">
    Documento generado desde el Markdown de <b>docs/system-documentation/</b>
    con <b>tool/build_system_documentation_pdf.py</b>. El Markdown es la fuente:
    no editar este PDF.
  </div>
</div>
<div><pdf:nextpage /></div>
"""


def toc(entries: list[str]) -> str:
    if len(entries) < 4:
        return ""
    rows = "".join(
        f'<div class="toc-entry">{index}. {html.escape(entry)}</div>'
        for index, entry in enumerate(entries, start=1)
    )
    return f'<h2>Contenido</h2><div class="toc">{rows}</div><div><pdf:nextpage /></div>'


def footer(label: str) -> str:
    return (
        f'<div id="footer_content" class="footer">{html.escape(PRODUCT)} · '
        f'{html.escape(label)} · página <pdf:pagenumber /> de <pdf:pagecount /></div>'
    )


def read_version() -> str:
    match = re.search(
        r"^version:\s*(\S+)$",
        (ROOT / "pubspec.yaml").read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    return match.group(1) if match else "desconocida"


def read_commit() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except Exception:
        return "no disponible"


def to_html(md_module, text: str) -> str:
    converter = md_module.Markdown(
        extensions=["tables", "fenced_code", "sane_lists", "attr_list"],
        output_format="html",
    )
    return restore_diagrams(converter.convert(text))


def write_pdf(pisa_module, document: str, target: Path) -> bool:
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("wb") as handle:
        status = pisa_module.CreatePDF(
            document,
            dest=handle,
            encoding="utf-8",
            # Permite resolver las rutas de las imágenes de los diagramas.
            path=str(OUTPUT) + "/",
        )
    return not status.err


def build(md_module, pisa_module, path: Path, binary: str | None, stats: dict,
          version: str, commit: str, today: str) -> bool:
    text = path.read_text(encoding="utf-8")
    title = document_title(text, path.stem)
    sections = section_titles(text)
    prepared = replace_mermaid(text, binary, stats)
    # El `# título` ya aparece en la portada.
    prepared = re.sub(r"^# .*?$", "", prepared, count=1, flags=re.MULTILINE)
    body = to_html(md_module, prepared)
    document = (
        f"<html><head><meta charset='utf-8' /><style>{STYLESHEET}</style></head><body>"
        + cover(title, "Documentación de sistema", version, commit, today)
        + toc(sections)
        + body
        + footer(title)
        + "</body></html>"
    )
    target = OUTPUT / (path.stem + ".pdf")
    ok = write_pdf(pisa_module, document, target)
    size = target.stat().st_size if target.exists() else 0
    print(f"  {'OK ' if ok and size > 0 else 'X  '} {target.name}  ({size} bytes)")
    return ok and size > 0


def build_combined(md_module, pisa_module, paths: list[Path], binary: str | None,
                   stats: dict, version: str, commit: str, today: str) -> bool:
    pieces: list[str] = []
    titles: list[str] = []
    for path in paths:
        text = path.read_text(encoding="utf-8")
        titles.append(document_title(text, path.stem))
        prepared = replace_mermaid(text, binary, stats)
        pieces.append(to_html(md_module, prepared))
    document = (
        f"<html><head><meta charset='utf-8' /><style>{STYLESHEET}</style></head><body>"
        + cover(
            "Documentación de sistema",
            "Todos los documentos en un solo archivo",
            version,
            commit,
            today,
        )
        + toc(titles)
        + '<div><pdf:nextpage /></div>'.join(pieces)
        + footer("Documentación completa")
        + "</body></html>"
    )
    target = OUTPUT / "00-documentacion-completa.pdf"
    ok = write_pdf(pisa_module, document, target)
    size = target.stat().st_size if target.exists() else 0
    print(f"  {'OK ' if ok and size > 0 else 'X  '} {target.name}  ({size} bytes)")
    return ok and size > 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", help="Genera solo ese archivo, por nombre")
    parser.add_argument("--skip-combined", action="store_true")
    args = parser.parse_args()

    if not SOURCE.is_dir():
        fail(f"No existe {SOURCE.relative_to(ROOT).as_posix()}")

    md_module, pisa_module = require_dependencies()
    binary = mermaid_binary()
    if binary is None:
        print("aviso: `mmdc` no está instalado; los diagramas se incluirán como texto.")
        print("       Para renderizarlos: npm install -g @mermaid-js/mermaid-cli")

    documents = sorted(SOURCE.glob("*.md"))
    if args.only:
        documents = [item for item in documents if item.name == args.only]
        if not documents:
            fail(f"No se encontró {args.only}")

    # La portada va primero; el resto por número.
    documents.sort(key=lambda item: (item.stem != "README", item.stem))

    OUTPUT.mkdir(parents=True, exist_ok=True)
    version = read_version()
    commit = read_commit()
    today = date.today().isoformat()
    stats = {"rendered": 0, "fallback": 0}

    print(f"Generando PDF de {len(documents)} documento(s) · versión {version} · commit {commit}")
    failures = 0
    for path in documents:
        if not build(md_module, pisa_module, path, binary, stats, version, commit, today):
            failures += 1

    if not args.skip_combined and not args.only:
        if not build_combined(md_module, pisa_module, documents, binary, stats, version, commit, today):
            failures += 1

    print(f"Diagramas renderizados: {stats['rendered']} · como texto: {stats['fallback']}")
    if failures:
        fail(f"{failures} documento(s) no se generaron correctamente")
    print("PDF generados en docs/system-documentation/pdf/")


if __name__ == "__main__":
    main()
