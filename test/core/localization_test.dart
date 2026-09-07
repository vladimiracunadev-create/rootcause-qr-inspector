import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/core/localization/app_localizations.dart';
import 'package:rootcause_qr_inspector/models/app_settings.dart';

void main() {
  test('offers Spanish, English, French and German', () {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(<Locale>[
        const Locale('es', 'CL'),
        const Locale('es'),
        const Locale('en'),
        const Locale('fr'),
        const Locale('de'),
      ]),
    );
    for (final String code in <String>['es', 'en', 'fr', 'de']) {
      expect(AppLocalizations.delegate.isSupported(Locale(code)), isTrue);
    }
    expect(
      AppLocalizations.delegate.isSupported(const Locale('it')),
      isFalse,
    );
  });

  test('primary navigation and Inventory help resolve in every language', () {
    final Map<String, List<String>> expected = <String, List<String>>{
      'es': <String>['Escanear', 'Inventario', 'Cómo usar Inventario'],
      'en': <String>['Inspect', 'Inventory', 'How to use Inventory'],
      'fr': <String>['Inspecter', 'Inventaire', 'Comment utiliser Inventaire'],
      'de': <String>['Prüfen', 'Inventar', 'Inventar verwenden'],
    };

    for (final MapEntry<String, List<String>> entry in expected.entries) {
      final AppLocalizations strings = AppLocalizations(Locale(entry.key));
      expect(strings.scan, entry.value[0]);
      expect(strings.inventory, entry.value[1]);
      expect(strings.inventoryGuide, entry.value[2]);
      expect(strings.tabDescription(1), isNotEmpty);
    }
  });

  test('settings map each explicit language to its locale', () {
    expect(const AppSettings(language: AppLanguage.system).locale, isNull);
    expect(
      const AppSettings(language: AppLanguage.en).locale,
      const Locale('en'),
    );
    expect(
      const AppSettings(language: AppLanguage.fr).locale,
      const Locale('fr'),
    );
    expect(
      const AppSettings(language: AppLanguage.de).locale,
      const Locale('de'),
    );
  });

  testWidgets('AppText translates registered copy without altering payloads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Column(
          children: <Widget>[
            AppText('Inventario'),
            AppText('PAYLOAD-123'),
          ],
        ),
      ),
    );

    expect(find.text('Inventar'), findsOneWidget);
    expect(find.text('PAYLOAD-123'), findsOneWidget);
  });
}
