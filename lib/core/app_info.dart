/// Single place where the application version is written for the interface.
///
/// La fuente heredada sufrió una deriva entre la versión construida y la
/// mostrada. `tool/validate_structure.py` compara esta constante con
/// `pubspec.yaml` y falla si divergen, para que el problema no vuelva en
/// silencio.
///
/// It is a constant rather than a runtime lookup on purpose: reading the real
/// package metadata would add a plugin dependency to display a string that is
/// already known when the package is built.
library;

/// Version shown in the interface, without the build number.
const String appVersion = '0.1.0';

/// Product name shown in the interface.
const String appName = 'RootCause QR Inspector';
