/// Fallo de arranque reducido a lo que se puede mostrar sin riesgo.
///
/// El texto visible es siempre el mismo y no proviene de la excepción; lo
/// único variable es el tipo de error y una huella de las primeras líneas de
/// la pila, suficiente para correlacionar dos informes del mismo problema.
class StartupFailure {
  const StartupFailure({required this.errorType, required this.message, required this.stackFingerprint});

  final String errorType;
  final String message;
  final String stackFingerprint;

  factory StartupFailure.from(Object error, StackTrace stack) {
    final int hash = Object.hash(error.runtimeType.toString(), stack.toString().split('\n').take(4).join('|'));
    return StartupFailure(
      errorType: error.runtimeType.toString(),
      message: 'No fue posible inicializar uno o más servicios locales.',
      stackFingerprint: hash.toUnsigned(32).toRadixString(16).padLeft(8, '0'),
    );
  }
}
