# Roadmap

El roadmap expresa dirección, no una promesa de fecha. Una capacidad solo se
comunica como entregada cuando existe código, prueba, documentación y gate.

## 0.1 — contrato inicial

- motor local de 26 reglas con ids estables;
- separación entre observación, hallazgo, hipótesis y decisión;
- evidencia `rootcause.evidence.qr.v1` redactada por defecto;
- captura, parsers, historial e inventario cifrados heredados y adaptados;
- Android e iOS como targets de aplicación; web solo como canal de demostración;
- validación en tablet Android e iPad antes de ampliar el soporte móvil;
- CI, SBOM, inventario de licencias, landing y documentación de límites.

El cierre binario de 0.1 requiere completar la matriz física, firma y revisión
de distribución descritas en [`RELEASE.md`](RELEASE.md).

## 0.2 — candidatos

- administración visual de políticas de marca y dominio;
- skeleton Unicode completo según UTS #39;
- dominio registrable basado en Public Suffix List versionada;
- cadena de evidencia administrada por la interfaz;
- importación/exportación explícita hacia un esquema común RootCause;
- más fixtures de Micro QR, PDF417, Aztec, Data Matrix, EAN y UPC.

## Evolución posterior

- fuentes remotas opt-in, separadas del motor local y de su política de
  privacidad;
- attestations o firmas de evidencia cuando exista gestión real de identidad y
  claves;
- adaptadores empresariales para políticas y correlación, sin convertirlos en
  telemetría por defecto.

## No objetivos

- abrir automáticamente un QR;
- declarar que un enlace, pago o beneficiario es seguro;
- custodiar credenciales, OTP, semillas o claves privadas;
- rastrear a la persona o monetizar datos de escaneo;
- reemplazar navegador aislado, antivirus, EDR o validación humana.
