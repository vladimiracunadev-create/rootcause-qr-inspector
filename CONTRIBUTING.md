# Contribuir a RootCause QR Inspector

Gracias por ayudar a mejorar el sensor. Los cambios deben conservar su principio
central: registrar hechos observables, separar las hipótesis y no presentar un
puntaje heurístico como probabilidad o veredicto.

## Preparar el entorno

Se requiere Flutter 3.44.7, Dart 3.12 o superior y Python 3.12:

```bash
flutter pub get
python3 tool/bootstrap.py --platforms android,web
python3 tool/validate_structure.py --require-lock
python3 tool/verify_rootcause_contract.py
flutter analyze --fatal-infos
flutter test
```

Las carpetas nativas son generadas y no se versionan. Consulta
[`docs/quality/COMPATIBILITY_CONTRACT.md`](docs/quality/COMPATIBILITY_CONTRACT.md)
antes de cambiar dependencias o requisitos de plataforma.

## Cambiar o añadir una regla

Una regla no está completa hasta actualizar en el mismo cambio:

1. el motor y su id estable;
2. los textos visibles y la categoría;
3. casos positivos, negativos y de falso positivo;
4. [`docs/rootcause/HEURISTICS.md`](docs/rootcause/HEURISTICS.md);
5. el esquema y el verificador del contrato, cuando corresponda.

Documenta qué hecho local observa, por qué importa, qué limitación mantiene y
qué acción permite. No añadas reputación remota, telemetría ni ejecución
automática de cargas como efecto lateral oculto.

## Pull requests

Mantén cada cambio enfocado, actualiza `CHANGELOG.md` si modifica conducta
visible y describe qué comandos ejecutaste. No adjuntes QR ni exportaciones con
datos reales. Para vulnerabilidades, usa el proceso privado de
[`SECURITY.md`](SECURITY.md).
