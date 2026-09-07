import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/scan_persistence_policy.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

void main() {
  test('la persistencia automática excluye secretos y pagos', () {
    final List<ScanRecord> records = <ScanRecord>[
      ScanRecord.manual(
        rawValue: 'https://normal.example',
        format: 'QR Code',
        source: 'Imagen · 1',
      ),
      ScanRecord.manual(
        rawValue: 'https://normal.example/callback?token=synthetic',
        format: 'QR Code',
        source: 'Imagen · 1',
      ),
      ScanRecord.manual(
        rawValue: 'WIFI:T:WPA;S:Lab;P:synthetic;;',
        format: 'QR Code',
        source: 'PDF · página 5',
      ),
      ScanRecord.manual(
        rawValue: 'bitcoin:bc1qexample?amount=0.01',
        format: 'QR Code',
        source: 'Imagen · 2',
      ),
    ];

    final List<ScanRecord> eligible = ScanPersistencePolicy.eligible(records);

    expect(eligible, hasLength(1));
    expect(eligible.single.rawValue, 'https://normal.example');
  });
}
