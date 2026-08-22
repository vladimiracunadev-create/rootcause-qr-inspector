import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rootcause_qr_inspector/bootstrap_host.dart';
import 'package:rootcause_qr_inspector/core/diagnostics/app_diagnostics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  runZonedGuarded<void>(
    () => runApp(const BootstrapHost()),
    (Object error, StackTrace stack) => AppDiagnostics.instance.record(error, stack, area: 'root_zone'),
  );
}
