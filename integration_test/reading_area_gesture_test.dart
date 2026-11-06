import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/bootstrap_host.dart';

/// Pellizco real sobre la aplicación real, en un dispositivo.
///
/// Ninguna prueba de widget puede sostener este gesto: la vista previa es
/// `MobileScanner`, que necesita la plataforma. Aquí la aplicación arranca
/// completa —base cifrada, preferencias, cámara— y el gesto entra por donde
/// entra el de un dedo humano, con dos punteros.
///
/// **Requisito.** La cámara tiene que estar concedida antes de ejecutar:
///
/// ```text
/// adb shell pm grant dev.vladimiracuna.rootcause_qr_inspector android.permission.CAMERA
/// ```
///
/// Sin el permiso, el arranque de la cámara queda pendiente durante toda la
/// prueba y la excepción llega al desmontaje (R-20 del registro de riesgos).
///
/// **Nada de `pumpAndSettle` aquí.** Con la cámara leyendo, la línea que
/// recorre el marco anima sin parar, así que esperar a que el árbol se quede
/// quieto no termina nunca: se bombean cuadros contados.
///
/// Lo que esta prueba **no** demuestra: que el pellizco se sienta natural, que
/// no compita con el toque de enfoque de una cámara física ni que el porcentaje
/// se lea a pleno sol. Eso sigue siendo matriz física y sigue declarado como
/// pendiente.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Bombea cuadros contados en lugar de esperar reposo.
  Future<void> advance(
    WidgetTester tester, {
    int frames = 12,
    Duration step = const Duration(milliseconds: 100),
  }) async {
    for (int frame = 0; frame < frames; frame++) {
      await tester.pump(step);
    }
  }

  /// Separa o junta dos punteros sobre el centro de la vista previa.
  ///
  /// Hacia dentro se empieza con los dedos **separados**: un pellizco solo
  /// puede reducir la distancia que ya existe, y moverlos más de la mitad del
  /// hueco inicial los cruza y vuelve a abrir la escala. Esa confusión fue el
  /// primer resultado de esta prueba, y de ahí salió la corrección de la
  /// aritmética del gesto.
  Future<void> pinch(WidgetTester tester, {required bool outward}) async {
    final Offset center = tester.getCenter(find.byType(MobileScanner).first);
    // Separa: 24 → 120 de medio hueco (escala 5). Junta: 120 → 20 (escala
    // 0,17). Las dos pasan de sobra del cuádruple que recorre el rango.
    final double from = outward ? 24 : 120;
    final double to = outward ? 120 : 20;

    final TestGesture left = await tester.startGesture(
      center - Offset(from, 0),
    );
    final TestGesture right = await tester.startGesture(
      center + Offset(from, 0),
    );
    // En pasos: un salto único no deja al reconocedor calcular la escala.
    const int steps = 10;
    final double stride = (to - from) / steps;
    for (int step = 0; step < steps; step++) {
      await left.moveBy(Offset(-stride, 0));
      await right.moveBy(Offset(stride, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await left.up();
    await right.up();
    // La amplitud se persiste al levantar los dedos: hay que dejar correr esa
    // escritura antes de mirar la pantalla.
    await advance(tester, frames: 8);
  }

  testWidgets('el pellizco maximiza y minimiza la zona de lectura', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BootstrapHost());
    await advance(tester, frames: 40, step: const Duration(milliseconds: 250));

    // Punto de partida: encabezado a la vista y amplitud mínima.
    expect(find.text('ROOTCAUSE · SEGURIDAD QR'), findsOneWidget);
    expect(find.byType(MobileScanner), findsAtLeastNWidgets(1));

    await pinch(tester, outward: true);

    // A pantalla completa el encabezado se retira y el indicador declara el
    // máximo.
    expect(find.text('ROOTCAUSE · SEGURIDAD QR'), findsNothing);
    expect(find.text('Zona de lectura 100 % · máxima'), findsOneWidget);

    await pinch(tester, outward: false);

    // Y vuelve, que es la mitad que suele faltar.
    expect(find.text('ROOTCAUSE · SEGURIDAD QR'), findsOneWidget);
    expect(find.text('Zona de lectura 50 %'), findsOneWidget);
  });
}
