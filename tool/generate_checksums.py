#!/usr/bin/env python3
"""Escribe el SHA-256 de cada archivo en el formato de `sha256sum`.

La segunda columna es el **nombre base**, no la ruta recibida. El motivo es
concreto: quien descarga un artefacto y su `.sha256` los deja juntos en una
carpeta y ejecuta `sha256sum -c`. Si el fichero apuntara a la ruta interna de la
CI —`build/rootcause-...apk`— la comprobación fallaría con «No such file or
directory» aunque el binario fuese correcto.

Uso:

    python tool/generate_checksums.py ARCHIVO [ARCHIVO...] > SHA256SUMS.txt

Los argumentos que no son un archivo existente se ignoran en silencio, para que
un glob sin coincidencias no rompa un paso de CI.
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

# 1 MiB: evita cargar en memoria un APK de decenas de megabytes.
_CHUNK = 1024 * 1024


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(_CHUNK), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    # `sha256sum -c` no acepta finales de línea CRLF: interpreta el retorno de
    # carro como parte del nombre del archivo. En Windows, `print` los produce
    # por defecto, así que la salida se fija a LF de forma explícita.
    sys.stdout.reconfigure(newline="\n")
    files = [Path(value) for value in sys.argv[1:] if Path(value).is_file()]
    for path in files:
        print(f"{sha256(path)}  {path.name}")


if __name__ == "__main__":
    main()
