# Datos de identidad de dominio

Dos tablas de terceros entran en este producto y sostienen las reglas de
identidad del motor. Las dos envejecen, y por eso llevan su procedencia escrita
dentro del archivo generado.

## Qué hay, de dónde viene y para qué

| Fuente original | Archivo en el repositorio | Genera | Sostiene |
|---|---|---|---|
| [Public Suffix List](https://publicsuffix.org/list/public_suffix_list.dat) (Mozilla, MPL-2.0) | `assets/data/public_suffix_list.dat` | `lib/core/investigation/public_suffix_data.dart` | dominio registrable, `host-embedded-suffix`, comparación de familias en `redirect-nested-domain` |
| [confusables.txt](https://www.unicode.org/Public/security/latest/confusables.txt) (Unicode, UTS #39) | `assets/data/unicode_confusables.txt` | `lib/core/investigation/unicode_confusables_data.dart` | esqueleto de confusión, `host-whole-script-confusable`, comparación de marca |

Los dos archivos originales se conservan **sin modificar**, con su aviso de
licencia intacto. Las tablas generadas derivan de ellos y conservan los
términos de su origen —MPL-2.0 para la lista de sufijos, los términos de uso de
Unicode para los confusables—, no la Apache-2.0 del repositorio; cada archivo
generado lo declara en su cabecera.

Los `.dat`/`.txt` no se declaran como assets de Flutter: no se leen en
ejecución. Están para que cualquiera pueda regenerar las tablas y comprobar que
el código contiene lo que dice contener.

## Alcance declarado

**Public Suffix List.** Se implementa el algoritmo publicado completo: regla
coincidente más larga, comodines (`*.ck`), excepciones (`!www.ck`) y regla
implícita `*`. Se cargan las dos secciones del archivo; `icannOnly` deja fuera
la privada cuando la pregunta es «¿esta etiqueta imita un dominio de primer
nivel?», donde `github.io` no viene al caso.

**Confusables.** Solo se incorporan las equivalencias **cuyo destino es
ASCII**. Un host en cirílico que se lee como una marca latina es el ataque que
cubre esta tabla; una equivalencia entre dos escrituras no latinas no suplanta
a nadie en este producto. Además **no** hay normalización NFD —Dart no la
trae—, así que un carácter precompuesto ausente de la tabla se queda como está.
Esto no es UTS #39 completo y no debe presentarse como tal.

## Envejecimiento: el límite que importa

`publicsuffix.org` cambia cada semana. `confusables.txt` cambia con cada
versión de Unicode. Las copias incluidas tienen fecha, y esa fecha está en la
cabecera del archivo generado junto al SHA-256 de la fuente.

Consecuencia concreta y conservadora: un sufijo creado después de esa fecha no
se reconoce, el host cae en la regla implícita `*` y el dominio registrable
sale más corto de lo que debería. El motor no inventa; se queda atrás, y lo
dice.

## Cómo se actualiza

```bash
curl -o assets/data/public_suffix_list.dat https://publicsuffix.org/list/public_suffix_list.dat
```

```bash
curl -o assets/data/unicode_confusables.txt https://www.unicode.org/Public/security/latest/confusables.txt
```

```bash
python tool/generate_identity_data.py
```

Después, el gate de siempre: `flutter analyze --fatal-infos`, `flutter test` y
`python tool/verify_rootcause_contract.py`. La CI ejecuta
`python tool/generate_identity_data.py --check`, que falla si los archivos
generados dejan de corresponder a sus fuentes — editar a mano la tabla queda
descartado.

Actualizar estas tablas **no** obliga a subir `engineVersion`: las reglas no
cambian, cambia el mundo que describen. Lo que sí obliga es tocar una regla o
su peso.
