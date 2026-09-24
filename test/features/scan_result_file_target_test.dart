import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/features/result/scan_result_sheet.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';
import 'package:rootcause_qr_inspector/services/settings_repository.dart';
import 'package:rootcause_qr_inspector/state/settings_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('los enlaces web usan navegador y una pestaña nueva', () {
    final Uri web = Uri.parse('https://example.com/path');
    final Uri phone = Uri.parse('tel:+56912345678');

    expect(launchModeForUri(web), LaunchMode.externalApplication);
    expect(webWindowNameForUri(web), '_blank');
    expect(launchModeForUri(phone), LaunchMode.platformDefault);
    expect(webWindowNameForUri(phone), isNull);
  });

  testWidgets('el destino y host real siguen legibles con texto ampliado', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final SettingsStore settings = SettingsStore(SettingsRepository());
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'https://trusted.example@evil.example/login',
      format: 'QR Code',
      source: 'PDF · página 3',
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: ScanResultsSheet(
            records: <ScanRecord>[record],
            settings: settings,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('DESTINO INTERPRETADO'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('DESTINO INTERPRETADO'), findsOneWidget);
    expect(find.text('HOST REAL'), findsOneWidget);
    expect(find.text('evil.example'), findsWidgets);
    expect(
      find.text('No se ha navegado ni resuelto una redirección remota.'),
      findsOneWidget,
    );
  });

  testWidgets('un resultado bloqueado no ofrece acción externa', (
    WidgetTester tester,
  ) async {
    final SettingsStore settings = SettingsStore(SettingsRepository());
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'javascript:alert(1)',
      format: 'QR Code',
      source: 'Imagen · 1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScanRecordCard(record: record, settings: settings),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.open_in_new), findsNothing);
    expect(find.textContaining('acción bloqueada'), findsWidgets);
  });
}
