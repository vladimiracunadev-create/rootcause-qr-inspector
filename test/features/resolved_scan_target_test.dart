import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/features/result/resolved_scan_target.dart';
import 'package:rootcause_qr_inspector/models/parsed_content.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

void main() {
  test('una URL con userinfo hace evidente el host real sin navegar', () {
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'https://trusted.example@evil.example/login',
      format: 'QR Code',
      source: 'PDF · página 3',
    );

    final ResolvedScanTarget target = ResolvedScanTarget.fromRecord(record);

    expect(target.kind, ContentKind.url);
    expect(target.title, 'Destino web');
    expect(target.primaryLabel, 'Destino codificado');
    expect(target.normalizedHost, 'evil.example');
    expect(target.source, 'PDF · página 3');
    expect(target.requiresConfirmation, isTrue);
  });

  test('correo y Wi-Fi tienen destinos semánticos, no se fuerzan a URL', () {
    final ResolvedScanTarget email = ResolvedScanTarget.fromRecord(
      ScanRecord.manual(
        rawValue: 'mailto:person@example.com?subject=Hello',
        format: 'QR Code',
        source: 'Imagen · 1',
      ),
    );
    final ResolvedScanTarget wifi = ResolvedScanTarget.fromRecord(
      ScanRecord.manual(
        rawValue: 'WIFI:T:WPA;S:Laboratorio;P:synthetic;;',
        format: 'QR Code',
        source: 'Imagen · 2',
      ),
    );

    expect(email.title, 'Acción de correo');
    expect(email.primaryLabel, 'Destinatario');
    expect(email.primaryValue, 'person@example.com');
    expect(wifi.title, 'Red Wi-Fi');
    expect(wifi.primaryValue, 'Laboratorio');
    expect(wifi.sensitive, isTrue);
    expect(wifi.effectiveUri, isNull);
  });

  test('texto permanece inspectOnly y no es accionable', () {
    final ResolvedScanTarget target = ResolvedScanTarget.fromRecord(
      ScanRecord.manual(
        rawValue: 'nota local sin acción',
        format: 'QR Code',
        source: 'Imagen · 1',
      ),
    );

    expect(target.title, 'Texto sin acción externa');
    expect(target.actionable, isFalse);
    expect(target.effectiveUri, isNull);
  });

  test('un esquema ejecutable bloqueado nunca es accionable', () {
    final ResolvedScanTarget target = ResolvedScanTarget.fromRecord(
      ScanRecord.manual(
        rawValue: 'javascript:alert(1)',
        format: 'QR Code',
        source: 'Imagen · 1',
      ),
    );

    expect(target.blocked, isTrue);
    expect(target.actionable, isFalse);
  });
}
