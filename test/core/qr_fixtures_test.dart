import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation_engine.dart';
import 'package:rootcause_qr_inspector/services/content_interpreter.dart';

/// Ejecuta el banco de regresión declarado en `fixtures/qr/manifest.json`.
///
/// Hasta ahora ese archivo solo se comprobaba por estructura
/// —`tool/verify_rootcause_contract.py` miraba que los ids existieran y que
/// los hosts fueran reservados—, pero **nadie lo ejecutaba**: un fixture podía
/// declarar `expectedAction: block` y el motor devolver `allow` sin que ninguna
/// prueba lo notara. Aquí cada caso declarado se analiza de verdad.
void main() {
  final File manifestFile = File('fixtures/qr/manifest.json');

  test('el manifiesto de fixtures existe y declara su esquema', () {
    expect(manifestFile.existsSync(), isTrue);
    final Map<String, Object?> manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
    expect(manifest['schema'], 'rootcause.qr-fixtures.v1');
    expect(manifest['cases'], isA<List<Object?>>());
  });

  final Map<String, Object?> manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
  final List<Object?> cases = manifest['cases'] as List<Object?>;

  for (final Object? raw in cases) {
    final Map<String, Object?> fixture = Map<String, Object?>.from(
      raw as Map<Object?, Object?>,
    );
    final String id = fixture['id'] as String;

    test('fixture $id se comporta como lo declara el manifiesto', () {
      final String payload = fixture['payload'] as String;
      final QrInvestigation result = QrInvestigationEngine.analyze(
        payload,
        parsed: ContentInterpreter.parse(payload),
        analyzedAt: DateTime.utc(2026, 11, 6),
      );
      final List<String> ids = result.findings
          .map((QrFinding item) => item.id)
          .toList(growable: false);

      expect(
        result.severity.name,
        fixture['expectedSeverity'],
        reason: '$id: severidad. Hallazgos: $ids',
      );
      expect(
        result.action.name,
        fixture['expectedAction'],
        reason: '$id: acción. Hallazgos: $ids',
      );
      for (final Object? expected in fixture['mustInclude'] as List<Object?>) {
        expect(ids, contains(expected), reason: '$id: falta $expected');
      }
      for (final Object? forbidden in fixture['mustExclude'] as List<Object?>) {
        expect(
          ids,
          isNot(contains(forbidden)),
          reason: '$id: no debía incluir $forbidden',
        );
      }
      // Toda regla declarada en un fixture tiene que haberse evaluado: un id
      // ausente de `evaluatedRuleIds` significa que la regla no se ejecutó, no
      // que no aplicó.
      for (final Object? expected in fixture['mustInclude'] as List<Object?>) {
        expect(result.evaluatedRuleIds, contains(expected), reason: id);
      }
    });
  }
}
