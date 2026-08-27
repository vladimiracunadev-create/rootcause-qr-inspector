#!/usr/bin/env python3
"""Verifica coherencia entre motor, esquema, textos, fixtures y versión.

No ejecuta Dart y no reemplaza `flutter test`. Su objetivo es impedir que una
regla cambie en un archivo y quede huérfana en el resto del contrato.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(relative: str):
    path = ROOT / relative
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"JSON inválido en {relative}: {exc}")


def engine_rule_ids() -> set[str]:
    text = (ROOT / "lib/core/investigation/qr_investigation_engine.dart").read_text(
        encoding="utf-8"
    )
    ids = set(re.findall(r"evaluate\('([a-z0-9-]+)'\)", text))
    if len(ids) != 26:
        fail(f"El motor 0.1.0 debe declarar 26 reglas; encontró {len(ids)}")
    return ids


def schema_rule_ids(schema: dict) -> set[str]:
    try:
        ids = set(schema["$defs"]["findingId"]["enum"])
    except Exception as exc:
        fail(f"El esquema no expone $defs.findingId.enum: {exc}")
    return ids


def title_rule_ids() -> set[str]:
    text = (ROOT / "lib/core/investigation/qr_finding_text.dart").read_text(
        encoding="utf-8"
    )
    title_section = text.split("static String explanation", 1)[0]
    return set(re.findall(r"'([a-z0-9-]+)'\s*=>", title_section))


def check_rule_sets(ids: set[str], schema: dict) -> None:
    sources = {
        "schema": schema_rule_ids(schema),
        "textos": title_rule_ids(),
    }
    for name, actual in sources.items():
        missing = sorted(ids - actual)
        extra = sorted(actual - ids)
        if missing or extra:
            fail(f"Desalineación motor↔{name}: faltan={missing}, sobran={extra}")

    heuristics = (ROOT / "docs/rootcause/HEURISTICS.md").read_text(
        encoding="utf-8"
    )
    undocumented = sorted(rule_id for rule_id in ids if f"`{rule_id}`" not in heuristics)
    if undocumented:
        fail(f"Reglas sin documentación: {undocumented}")


def check_fixtures(ids: set[str]) -> None:
    manifest = load_json("fixtures/qr/manifest.json")
    if manifest.get("schema") != "rootcause.qr-fixtures.v1":
        fail("Schema de fixtures incorrecto")
    cases = manifest.get("cases")
    if not isinstance(cases, list) or len(cases) < 12:
        fail("Se requieren al menos 12 casos de regresión")

    seen: set[str] = set()
    covered: set[str] = set()
    actions = {"allow", "confirm", "inspectOnly", "block"}
    severities = {"normal", "warning", "critical"}
    for case in cases:
        if not isinstance(case, dict):
            fail("Cada fixture debe ser un objeto")
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            fail(f"Id de fixture inválido o duplicado: {case_id}")
        seen.add(case_id)
        if case.get("expectedAction") not in actions:
            fail(f"Acción inválida en {case_id}")
        if case.get("expectedSeverity") not in severities:
            fail(f"Severidad inválida en {case_id}")
        for key in ("mustInclude", "mustExclude"):
            values = case.get(key)
            if not isinstance(values, list) or not all(isinstance(item, str) for item in values):
                fail(f"{key} inválido en {case_id}")
            unknown = sorted(set(values) - ids)
            if unknown:
                fail(f"{case_id} referencia reglas inexistentes: {unknown}")
        covered.update(case["mustInclude"])

        payload = case.get("payload")
        if not isinstance(payload, str) or not payload:
            fail(f"Carga vacía en {case_id}")
        if payload.startswith(("http://", "https://")):
            host = (urlsplit(payload).hostname or "").lower()
            allowed_real_fixture_hosts = {"bit.ly"}
            if (
                host not in allowed_real_fixture_hosts
                and not host.endswith(".example")
                and host != "example.com"
                and not host.startswith("192.168.")
                and "@" not in payload.split("/", 3)[2]
            ):
                fail(f"Fixture {case_id} usa un host no reservado: {host}")

    required_coverage = {
        "authority-userinfo",
        "download-dangerous-extension",
        "host-private-or-local",
        "host-punycode",
        "host-shortener",
        "opaque-binary-payload",
        "payment-instruction",
        "redirect-nested-domain",
        "scheme-blocked",
        "sensitive-secret",
        "transport-http",
    }
    missing = sorted(required_coverage - covered)
    if missing:
        fail(f"Fixtures mínimos sin cobertura: {missing}")


def check_policy() -> None:
    policy = load_json("config/rootcause-qr-policy.example.json")
    if policy.get("schema") != "rootcause.qr-policy.v1":
        fail("Schema de política incorrecto")
    brands = policy.get("trustedBrands")
    if not isinstance(brands, list) or not brands:
        fail("La política de ejemplo necesita al menos una marca sintética")
    for brand in brands:
        if not isinstance(brand, dict):
            fail("Marca inválida en política")
        hosts = brand.get("allowedHosts")
        tokens = brand.get("tokens")
        if not isinstance(hosts, list) or not hosts:
            fail(f"Marca sin allowedHosts: {brand.get('id')}")
        if not all(isinstance(host, str) and host.endswith(".example") for host in hosts):
            fail(f"La política de ejemplo solo puede usar .example: {brand.get('id')}")
        if not isinstance(tokens, list) or not all(
            isinstance(token, str) and len(re.sub(r"[^a-zA-Z0-9]", "", token)) >= 4
            for token in tokens
        ):
            fail(f"Tokens inválidos en {brand.get('id')}")


def check_version_and_identity() -> None:
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+[0-9]+$", pubspec, re.M)
    if not match:
        fail("Versión pubspec inválida")
    version = match.group(1)
    app_info = (ROOT / "lib/core/app_info.dart").read_text(encoding="utf-8")
    if f"const String appVersion = '{version}';" not in app_info:
        fail("appVersion no coincide con pubspec")
    if "const String appName = 'RootCause QR Inspector';" not in app_info:
        fail("appName incorrecto")
    package = re.search(r"^name:\s*([a-z0-9_]+)$", pubspec, re.M)
    if package is None or package.group(1) != "rootcause_qr_inspector":
        fail("Nombre de paquete Dart incorrecto")


def check_redaction_contract() -> None:
    exporter = (ROOT / "lib/core/investigation/qr_evidence_exporter.dart").read_text(
        encoding="utf-8"
    )
    required = (
        "payload-omitted",
        "none-user-authorized",
        "if (includeRawPayload) 'rawPayload'",
        "investigation.remove('effectiveUri')",
        "_canonicalJson(content)",
        "checksum-only-not-authenticated",
        "bundleHash",
    )
    for marker in required:
        if marker not in exporter:
            fail(f"Contrato de redacción/integridad incompleto: {marker}")

    ui = (ROOT / "lib/features/result/scan_result_sheet.dart").read_text(
        encoding="utf-8"
    )
    disclaimer = "Esto no demuestra que el destino sea seguro."
    if disclaimer not in ui:
        fail("La UI perdió el descargo obligatorio para resultado normal")
    if "record.investigation.action == QrActionDecision.confirm" not in ui:
        fail("La UI dejó de respetar la decisión confirm del motor")

    engine = (ROOT / "lib/core/investigation/qr_investigation_engine.dart").read_text(
        encoding="utf-8"
    )
    if "sha256.convert(utf8.encode(rawValue))" not in engine:
        fail("La huella debe cubrir la carga exacta, no la copia normalizada")

    importer = (ROOT / "lib/services/import_service.dart").read_text(encoding="utf-8")
    if "trustDerivedAnalysis: false" not in importer:
        fail("La importación volvió a confiar en análisis derivados del respaldo")

    schema = load_json("schemas/rootcause-qr-evidence.schema.json")
    redacted_contract = json.dumps(schema.get("allOf", []), sort_keys=True)
    if "effectiveUri" not in redacted_contract:
        fail("El JSON Schema no prohíbe effectiveUri en paquetes redactados")


def main() -> None:
    schema = load_json("schemas/rootcause-qr-evidence.schema.json")
    if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        fail("El contrato de evidencia debe usar JSON Schema 2020-12")
    ids = engine_rule_ids()
    check_rule_sets(ids, schema)
    check_fixtures(ids)
    check_policy()
    check_version_and_identity()
    check_redaction_contract()
    print(
        "Contrato RootCause coherente: "
        f"{len(ids)} reglas · esquema · textos · fixtures · política · versión · redacción."
    )


if __name__ == "__main__":
    main()
