import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/app.dart';
import 'package:rootcause_qr_inspector/core/localization/app_localizations.dart';

void main() {
  const Key content = Key('content');

  Widget frame() => const MaterialApp(
        home: HandheldFrame(
          child: SizedBox.expand(key: content, child: ColoredBox(color: Color(0xFF006B66))),
        ),
      );

  Future<Rect> layout(WidgetTester tester, Size viewport) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(frame());
    return tester.getRect(find.byKey(content));
  }

  testWidgets('a phone-sized viewport is filled edge to edge', (WidgetTester tester) async {
    final Rect box = await layout(tester, const Size(400, 900));

    expect(box.left, 0);
    expect(box.width, 400);
  });

  testWidgets('exactly at the threshold the viewport is still filled', (WidgetTester tester) async {
    final Rect box = await layout(tester, const Size(HandheldFrame.maxWidth, 900));

    expect(box.left, 0);
    expect(box.width, HandheldFrame.maxWidth);
  });

  testWidgets('a wide viewport is centred at handheld width', (WidgetTester tester) async {
    const double viewport = 1600;
    final Rect box = await layout(tester, const Size(viewport, 900));

    expect(box.width, HandheldFrame.maxWidth);
    // Centred: the margin is identical on both sides.
    expect(box.left, viewport - box.right);
    expect(box.left, (viewport - HandheldFrame.maxWidth) / 2);
  });

  testWidgets('five Spanish navigation labels stay on one line at 320 dp', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final AppLocalizations strings = const AppLocalizations(Locale('es', 'CL'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: <NavigationDestination>[
              NavigationDestination(icon: const Icon(Icons.shield_outlined), label: strings.scan),
              NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: strings.inventory),
              NavigationDestination(icon: const Icon(Icons.qr_code_2_outlined), label: strings.generate),
              NavigationDestination(icon: const Icon(Icons.history_outlined), label: strings.history),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), label: strings.settings),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final String label in <String>[strings.scan, strings.inventory, strings.generate, strings.history, strings.settings]) {
      expect(tester.getSize(find.text(label)).height, lessThan(22));
    }
  });
}
