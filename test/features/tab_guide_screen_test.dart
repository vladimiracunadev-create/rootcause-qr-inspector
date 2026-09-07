import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/core/localization/app_localizations.dart';
import 'package:rootcause_qr_inspector/features/help/tab_guide_screen.dart';

void main() {
  testWidgets('Inventory guide is complete and scrollable in English', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: TabGuideScreen(focusInventory: true),
        ),
      ),
    );

    expect(find.text('Quick app guide'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('How to use Inventory'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('How to use Inventory'), findsOneWidget);
    expect(find.textContaining('Scan each physical unit'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Settings'),
      280,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
