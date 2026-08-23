import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// The application ships a Spanish interface. English keys already exist here,
  /// but the rest of the screens still hold Spanish literals, so offering
  /// English would produce a half-translated interface: an English navigation
  /// bar over Spanish content. The locale is therefore not exposed until every
  /// screen reads its strings from this class.
  static const List<Locale> supportedLocales = <Locale>[Locale('es', 'CL'), Locale('es')];

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get _es => locale.languageCode != 'en';
  String get appTitle => 'RootCause QR Inspector';
  // Keep navigation labels short enough for five destinations on 320 dp
  // phones. The screen title retains the full security-inspection wording.
  String get scan => _es ? 'Escanear' : 'Scan';
  String get inventory => _es ? 'Inventario' : 'Inventory';
  String get generate => _es ? 'Generar' : 'Generate';
  String get history => _es ? 'Historial' : 'History';
  String get settings => _es ? 'Ajustes' : 'Settings';
  String get scannerTitle => _es ? 'Inspector de seguridad QR' : 'QR security inspector';
  String get scannerSubtitle => _es
      ? 'Observa el destino, explica el riesgo y decide antes de actuar'
      : 'Observe the destination, explain the risk, and decide before acting';
  String get temporaryMode => _es ? 'Modo temporal' : 'Temporary mode';
  String get recoveryCenter => _es ? 'Centro de recuperación' : 'Recovery center';
  String get retry => _es ? 'Reintentar' : 'Retry';
  String get cancel => _es ? 'Cancelar' : 'Cancel';
  String get continueLabel => _es ? 'Continuar' : 'Continue';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppStringsContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
}
