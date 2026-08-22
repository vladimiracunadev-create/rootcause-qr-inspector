import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:rootcause_qr_inspector/core/app_info.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

/// Produce un paquete forense portable sin revelar la carga por defecto.
abstract final class QrEvidenceExporter {
  static const String schema = 'rootcause.evidence.qr.v1';

  static Map<String, Object?> toMap(
    ScanRecord record, {
    bool includeRawPayload = false,
    String? previousEvidenceHash,
  }) {
    if (previousEvidenceHash != null &&
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(previousEvidenceHash)) {
      throw ArgumentError.value(
        previousEvidenceHash,
        'previousEvidenceHash',
        'Debe ser un SHA-256 hexadecimal en minúsculas.',
      );
    }
    final Map<String, Object?> investigation =
        Map<String, Object?>.from(record.investigation.toJson());
    if (!includeRawPayload) {
      // `effectiveUri` puede contener la misma consulta, credencial o token que
      // la carga original. Un paquete redactado no debe recuperarla por una
      // ruta secundaria.
      investigation.remove('effectiveUri');
    }
    final Map<String, Object?> content = <String, Object?>{
      'schema': schema,
      'product': <String, Object?>{
        'name': appName,
        'version': appVersion,
      },
      'bundleId': _bundleId(record),
      'observedAt': record.scannedAt.toUtc().toIso8601String(),
      'observation': <String, Object?>{
        'source': record.source,
        'symbology': record.format,
        'contentKind': record.parsed.kind.name,
        'sensitive': record.isSensitive,
        'payloadBytes': utf8.encode(record.rawValue).length,
        'payloadSha256': record.investigation.payloadSha256,
        'redaction': includeRawPayload ? 'none-user-authorized' : 'payload-omitted',
        if (includeRawPayload) 'rawPayload': record.rawValue,
        if (includeRawPayload) 'parsed': record.parsed.toJson(),
      },
      'investigation': investigation,
      'integrity': <String, Object?>{
        'algorithm': 'SHA-256',
        'assurance': 'checksum-only-not-authenticated',
        if (previousEvidenceHash != null) 'previousEvidenceHash': previousEvidenceHash,
      },
    };
    final String bundleHash =
        sha256.convert(utf8.encode(_canonicalJson(content))).toString();
    final Map<String, Object?> integrity =
        Map<String, Object?>.from(content['integrity']! as Map<String, Object?>)
          ..['bundleHash'] = bundleHash;
    return <String, Object?>{...content, 'integrity': integrity};
  }

  static String toJson(
    ScanRecord record, {
    bool includeRawPayload = false,
    String? previousEvidenceHash,
  }) =>
      const JsonEncoder.withIndent('  ').convert(toMap(
        record,
        includeRawPayload: includeRawPayload,
        previousEvidenceHash: previousEvidenceHash,
      ));

  static bool verify(Map<String, dynamic> bundle) {
    final Map<String, dynamic> integrity =
        Map<String, dynamic>.from(bundle['integrity'] as Map? ?? const <String, dynamic>{});
    if (integrity['algorithm'] != 'SHA-256' ||
        integrity['assurance'] != 'checksum-only-not-authenticated') {
      return false;
    }
    final Object? rawExpected = integrity.remove('bundleHash');
    if (rawExpected is! String || rawExpected.isEmpty) return false;
    final Map<String, Object?> unsigned = Map<String, Object?>.from(bundle)
      ..['integrity'] = integrity;
    final String actual =
        sha256.convert(utf8.encode(_canonicalJson(unsigned))).toString();
    return actual == rawExpected;
  }

  /// Serialización determinista por claves para que reordenar un objeto JSON
  /// no invalide un paquete que conserva exactamente el mismo contenido.
  static String _canonicalJson(Object? value) {
    if (value is Map) {
      final List<String> keys = value.keys.map((Object? key) => '$key').toList()
        ..sort();
      return '{${keys.map((String key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  static String _bundleId(ScanRecord record) => sha256
      .convert(utf8.encode('${record.id}|${record.investigation.payloadSha256}|${record.scannedAt.toUtc().toIso8601String()}'))
      .toString()
      .substring(0, 24);
}
