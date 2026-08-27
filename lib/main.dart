import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rootcause_qr_inspector/bootstrap_host.dart';
import 'package:rootcause_qr_inspector/core/diagnostics/app_diagnostics.dart';

/// Punto de entrada: instala los capturadores de error antes de la interfaz.
///
/// El orden es intencional. `installGlobalErrorHandlers` y la zona guardada se
/// establecen antes de `runApp`, de modo que un fallo durante el arranque
/// llegue al diagnóstico privado en vez de terminar en una pantalla en blanco.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  runZonedGuarded<void>(
    () => runApp(const BootstrapHost()),
    (Object error, StackTrace stack) => AppDiagnostics.instance.record(error, stack, area: 'root_zone'),
  );
}
