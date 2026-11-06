#!/usr/bin/env python3
"""Genera los datos de identidad de dominio desde las fuentes originales.

Dos tablas, dos fuentes, un solo generador porque ambas sostienen la misma
pregunta: este host es el que la persona cree que es?

- `assets/data/public_suffix_list.dat` (Mozilla, MPL-2.0) produce las reglas de
  sufijo publico con las que se calcula el dominio registrable;
- `assets/data/unicode_confusables.txt` (Unicode, UTS #39) produce las
  equivalencias cuyo destino es ASCII, que son las que sostienen la
  suplantacion de una marca escrita en latin.

El archivo generado lleva la procedencia dentro: version declarada por la
fuente, fecha y SHA-256 del archivo de origen. Sin eso, una tabla de datos
dentro del codigo es una afirmacion sin respaldo.

Uso: python tool/generate_identity_data.py [--check]
"""
from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PSL_SOURCE = ROOT / "assets/data/public_suffix_list.dat"
CONFUSABLES_SOURCE = ROOT / "assets/data/unicode_confusables.txt"
PSL_OUTPUT = ROOT / "lib/core/investigation/public_suffix_data.dart"
CONFUSABLES_OUTPUT = ROOT / "lib/core/investigation/unicode_confusables_data.dart"

ASCII_TARGET = re.compile(r"^[0-9A-Za-z.\-]+$")
QUOTE = chr(39)


def sha256_of(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def chunked_literal(values: list[str], per_line: int = 24) -> str:
    """Escribe las reglas como literales adyacentes separados por salto.

    Un `Set` constante de diez mil literales tarda en analizarse y no se lee;
    un unico literal de 300 kB en una sola linea tampoco. Esto deja lineas
    cortas que Dart concatena en tiempo de compilacion.
    """
    lines: list[str] = []
    for index in range(0, len(values), per_line):
        piece = "\\n".join(values[index : index + per_line])
        tail = "\\n" if index + per_line < len(values) else ""
        lines.append("    " + QUOTE + piece + tail + QUOTE)
    return "\n".join(lines)


def parse_psl(text: str) -> tuple[list[str], list[str]]:
    icann: list[str] = []
    private: list[str] = []
    current: list[str] | None = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("// ===BEGIN ICANN DOMAINS==="):
            current = icann
            continue
        if line.startswith("// ===BEGIN PRIVATE DOMAINS==="):
            current = private
            continue
        if line.startswith("// ===END"):
            current = None
            continue
        if not line or line.startswith("//") or current is None:
            continue
        current.append(line)
    if len(icann) < 1000 or len(private) < 100:
        raise SystemExit(
            f"ERROR: secciones PSL inverosimiles (icann={len(icann)}, private={len(private)})"
        )
    return icann, private


def psl_version(text: str) -> str:
    match = re.search(r"^// VERSION: (.+)$", text, re.M)
    return match.group(1).strip() if match else "desconocida"


def parse_confusables(text: str) -> dict[int, str]:
    mapping: dict[int, str] = {}
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        parts = [part.strip() for part in line.split(";")]
        if len(parts) < 2 or not parts[0] or not parts[1]:
            continue
        try:
            source = int(parts[0], 16)
        except ValueError:
            continue
        try:
            target = "".join(chr(int(code, 16)) for code in parts[1].split())
        except ValueError:
            continue
        # Solo interesa lo que puede hacerse pasar por ASCII: un host escrito
        # en latin. Una equivalencia entre dos escrituras no latinas no
        # suplanta una marca latina y solo haria crecer la tabla.
        if source < 128 or not ASCII_TARGET.match(target):
            continue
        mapping[source] = target.lower()
    if len(mapping) < 400:
        raise SystemExit(f"ERROR: tabla de confusables inverosimil ({len(mapping)})")
    return mapping


def confusables_version(text: str) -> tuple[str, str]:
    version = re.search(r"^# Version: (.+)$", text, re.M)
    date = re.search(r"^# Date: (.+)$", text, re.M)
    return (
        version.group(1).strip() if version else "desconocida",
        date.group(1).strip() if date else "desconocida",
    )


def render_psl(text: str) -> str:
    icann, private = parse_psl(text)
    return f"""// GENERADO POR tool/generate_identity_data.py - NO EDITAR A MANO.
//
// Fuente: assets/data/public_suffix_list.dat
// Origen: https://publicsuffix.org/list/public_suffix_list.dat
// Version declarada por la fuente: {psl_version(text)}
// SHA-256 de la fuente: {sha256_of(PSL_SOURCE)}
// Reglas: {len(icann)} ICANN y {len(private)} privadas
//
// La lista es de Mozilla Foundation y se distribuye bajo Mozilla Public
// License 2.0. El archivo original, con su aviso de licencia intacto, vive en
// assets/data/public_suffix_list.dat y no se modifica aqui.
//
// Una lista de sufijos envejece: publicsuffix.org cambia cada semana. La fecha
// de arriba es la unica forma honesta de saber cuanto se ha quedado atras esta
// copia, y docs/rootcause/IDENTITY_DATA.md dice como actualizarla.
library;

/// Version declarada por la fuente, para la pantalla «Acerca de».
///
/// Se emite aqui y no se escribe a mano en la interfaz: asi la pantalla no
/// puede quedarse afirmando una version que ya no es la incluida.
const String kPublicSuffixListVersion = '{psl_version(text)}';

/// Reglas de la seccion ICANN, una por linea.
const String kIcannPublicSuffixRules =
{chunked_literal(icann)};

/// Reglas de la seccion privada, una por linea.
///
/// Son dominios que delegan subdominios a terceros - `github.io`,
/// `blogspot.com` - y por eso dos subdominios suyos pertenecen a duenos
/// distintos. Importan para decidir si dos hosts son la misma familia; no para
/// decidir si un sufijo va incrustado en el host.
const String kPrivatePublicSuffixRules =
{chunked_literal(private)};
"""


def render_confusables(text: str) -> str:
    mapping = parse_confusables(text)
    version, date = confusables_version(text)
    rows: list[str] = []
    for source, target in sorted(mapping.items()):
        literal = (
            '"' + target + '"' if QUOTE in target else QUOTE + target + QUOTE
        )
        rows.append(f"  0x{source:04X}: {literal},")
    entries = "\n".join(rows)
    return f"""// GENERADO POR tool/generate_identity_data.py - NO EDITAR A MANO.
//
// Fuente: assets/data/unicode_confusables.txt
// Origen: https://www.unicode.org/Public/security/latest/confusables.txt
// Version UTS #39: {version} - fecha de la fuente: {date}
// SHA-256 de la fuente: {sha256_of(CONFUSABLES_SOURCE)}
// Equivalencias con destino ASCII: {len(mapping)}
//
// Datos de Unicode, Inc., usados segun https://www.unicode.org/terms_of_use.html
//
// Alcance declarado: solo las equivalencias cuyo destino es ASCII. Un host
// escrito en cirilico que se lee como una marca latina es el ataque que esta
// tabla cubre; una equivalencia entre dos escrituras no latinas no suplanta a
// nadie en este producto y quedaria sin usar.
library;

/// Version de UTS #39 de la que salen las equivalencias.
const String kConfusablesVersion = '{version}';

/// Fecha declarada por la fuente.
const String kConfusablesSourceDate = '{date}';

/// Punto de codigo no ASCII y su equivalente ASCII segun UTS #39.
const Map<int, String> kConfusableAsciiMap = <int, String>{{
{entries}
}};
"""


def main() -> None:
    check = "--check" in sys.argv
    psl_text = PSL_SOURCE.read_text(encoding="utf-8")
    confusables_text = CONFUSABLES_SOURCE.read_text(encoding="utf-8")
    outputs = {
        PSL_OUTPUT: render_psl(psl_text),
        CONFUSABLES_OUTPUT: render_confusables(confusables_text),
    }
    stale: list[str] = []
    for path, content in outputs.items():
        if check:
            current = path.read_text(encoding="utf-8") if path.exists() else ""
            if current != content:
                stale.append(path.relative_to(ROOT).as_posix())
            continue
        path.write_text(content, encoding="utf-8")
        print(f"escrito {path.relative_to(ROOT).as_posix()} ({len(content)} bytes)")
    if check:
        if stale:
            print(f"ERROR: datos generados desincronizados: {stale}", file=sys.stderr)
            raise SystemExit(1)
        print("Datos de identidad sincronizados con sus fuentes.")


if __name__ == "__main__":
    main()
