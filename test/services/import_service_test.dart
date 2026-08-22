import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';
import 'package:rootcause_qr_inspector/services/import_service.dart';

void main() {
  test('history import previews valid, duplicate, and rejected records', () {
    final ScanRecord record = ScanRecord.manual(rawValue: 'https://example.com', format: 'QR', source: 'Test');
    final List<int> bytes = utf8.encode(jsonEncode(<String, Object?>{
      'application': 'RootCause QR Inspector',
      'schemaVersion': 2,
      'type': 'history',
      'records': <Object?>[record.toJson(), 'invalid'],
    }));

    final HistoryImportPreview preview = ImportService.parseHistoryBytes(bytes, existingIds: <String>{record.id});
    expect(preview.valid, 1);
    expect(preview.duplicates, 1);
    expect(preview.rejected, 1);
    expect(preview.apply(<String>{record.id}, ImportStrategy.skipDuplicates), isEmpty);
  });

  test('future schema is rejected before modifying data', () {
    final List<int> bytes = utf8.encode(jsonEncode(<String, Object?>{
      'application': 'RootCause QR Inspector',
      'schemaVersion': 999,
      'type': 'history',
      'records': <Object?>[],
    }));
    expect(
      () => ImportService.parseHistoryBytes(bytes, existingIds: const <String>{}),
      throwsA(isA<FormatException>()),
    );
  });

  test('duplicate records inside the same file are collapsed before import', () {
    final ScanRecord record = ScanRecord.manual(rawValue: 'same', format: 'QR', source: 'Test');
    final List<int> bytes = utf8.encode(jsonEncode(<String, Object?>{
      'application': 'RootCause QR Inspector',
      'schemaVersion': 2,
      'type': 'history',
      'records': <Object?>[record.toJson(), record.toJson()],
    }));

    final HistoryImportPreview preview = ImportService.parseHistoryBytes(bytes, existingIds: const <String>{});
    expect(preview.records, hasLength(1));
    expect(preview.duplicates, 1);
  });

  test('excessively deep JSON is rejected before persistence', () {
    dynamic nested = <String, Object?>{'value': true};
    for (int index = 0; index < ImportService.maxJsonDepth + 2; index++) {
      nested = <String, Object?>{'child': nested};
    }
    final List<int> bytes = utf8.encode(jsonEncode(nested));
    expect(
      () => ImportService.parseHistoryBytes(bytes, existingIds: const <String>{}),
      throwsA(isA<FormatException>()),
    );
  });

  test('un respaldo no puede inyectar un veredicto o id derivados', () {
    final ScanRecord record = ScanRecord.manual(
      rawValue: 'https://example.com/documento',
      format: 'QR',
      source: 'Test',
    );
    final Map<String, dynamic> forged = record.toJson()
      ..['id'] = 'id-controlado'
      ..['investigation'] = <String, Object?>{
        ...record.investigation.toJson(),
        'verdict': <String, Object?>{
          'severity': 'critical',
          'score': 100,
          'action': 'block',
        },
      };
    final List<int> bytes = utf8.encode(jsonEncode(<String, Object?>{
      'application': 'RootCause QR Inspector',
      'schemaVersion': 2,
      'type': 'history',
      'records': <Object?>[forged],
    }));

    final ScanRecord imported = ImportService.parseHistoryBytes(
      bytes,
      existingIds: const <String>{},
    ).records.single;

    expect(imported.id, isNot('id-controlado'));
    expect(imported.riskLevel.name, 'low');
    expect(imported.investigation.findings, isEmpty);
  });

}
