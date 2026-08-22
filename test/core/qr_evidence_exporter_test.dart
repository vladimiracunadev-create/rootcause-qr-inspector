import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_evidence_exporter.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

void main() {
  test('el paquete forense omite la carga por defecto y verifica su hash', () {
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'https://example.com/login?token=secreto',
      format: 'QR Code',
      source: 'Prueba',
    );

    final Map<String, dynamic> bundle = Map<String, dynamic>.from(
      jsonDecode(QrEvidenceExporter.toJson(record)) as Map,
    );
    final Map<String, dynamic> observation =
        Map<String, dynamic>.from(bundle['observation'] as Map);
    final Map<String, dynamic> investigation =
        Map<String, dynamic>.from(bundle['investigation'] as Map);

    expect(observation.containsKey('rawPayload'), isFalse);
    expect(observation['redaction'], 'payload-omitted');
    expect(investigation.containsKey('effectiveUri'), isFalse);
    expect(jsonEncode(bundle), isNot(contains('token=secreto')));
    expect(
      Map<String, dynamic>.from(bundle['integrity'] as Map)['assurance'],
      'checksum-only-not-authenticated',
    );
    expect(QrEvidenceExporter.verify(bundle), isTrue);

    observation['source'] = 'Alterado';
    bundle['observation'] = observation;
    expect(QrEvidenceExporter.verify(bundle), isFalse);
  });

  test('la inclusión de carga es explícita y queda declarada', () {
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'https://example.com/documento',
      format: 'QR Code',
      source: 'Prueba',
    );

    final Map<String, Object?> bundle = QrEvidenceExporter.toMap(
      record,
      includeRawPayload: true,
    );
    final Map<String, Object?> observation =
        Map<String, Object?>.from(bundle['observation']! as Map<String, Object?>);

    expect(observation['rawPayload'], record.rawValue);
    expect(observation['redaction'], 'none-user-authorized');
    expect(
      Map<String, Object?>.from(bundle['investigation']! as Map<String, Object?>)
          .containsKey('effectiveUri'),
      isTrue,
    );
  });

  test('el hash resiste reordenamiento de claves JSON', () {
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'https://example.com/documento',
      format: 'QR Code',
      source: 'Prueba',
    );
    final Map<String, dynamic> original = Map<String, dynamic>.from(
      jsonDecode(QrEvidenceExporter.toJson(record)) as Map,
    );
    final Map<String, dynamic> reordered = <String, dynamic>{
      for (final String key in original.keys.toList().reversed) key: original[key],
    };

    expect(QrEvidenceExporter.verify(reordered), isTrue);
  });

  test('rechaza un enlace anterior que no sea SHA-256 canónico', () {
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'https://example.com/documento',
      format: 'QR Code',
      source: 'Prueba',
    );

    expect(
      () => QrEvidenceExporter.toMap(
        record,
        previousEvidenceHash: 'no-es-un-sha256',
      ),
      throwsArgumentError,
    );
  });
}
