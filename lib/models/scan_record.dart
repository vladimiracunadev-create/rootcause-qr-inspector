import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_finding_text.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/core/security/scan_security_analyzer.dart';
import 'package:rootcause_qr_inspector/core/utils/barcode_labels.dart';
import 'package:rootcause_qr_inspector/models/parsed_content.dart';
import 'package:rootcause_qr_inspector/features/formats/domain/content_parser_registry.dart';

class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.rawValue,
    required this.displayValue,
    required this.format,
    required this.contentType,
    required this.scannedAt,
    required this.source,
    required this.riskLevel,
    required this.riskReasons,
    required this.canOpen,
    required this.parsed,
    required this.investigation,
    this.favorite = false,
    this.tags = const <String>[],
    this.notes = '',
  });

  factory ScanRecord.fromBarcode(Barcode barcode, {required String source, DateTime? scannedAt}) {
    final DateTime timestamp = scannedAt ?? DateTime.now();
    final String raw = payloadForBarcode(barcode);
    final Uint8List? binaryBytes = _decodedBytes(barcode.rawDecodedBytes);
    final String readable = (barcode.displayValue ?? barcode.rawValue ?? '').trim();
    final String display = readable.isNotEmpty
        ? readable
        : binaryBytes == null ? raw : 'Datos binarios (${binaryBytes.length} bytes)\n$raw';
    final ParsedContent parsed = ContentParserRegistry.instance.parse(raw);
    final SecurityAssessment assessment = ScanSecurityAnalyzer.analyze(
      raw,
      parsed: parsed,
      analyzedAt: timestamp,
    );
    final String digest = sha256.convert(utf8.encode('$raw|${timestamp.microsecondsSinceEpoch}')).toString().substring(0, 20);
    return ScanRecord(
      id: digest,
      rawValue: raw,
      displayValue: display,
      format: BarcodeLabels.format(barcode.format),
      contentType: parsed.title,
      scannedAt: timestamp,
      source: source,
      riskLevel: assessment.level,
      riskReasons: assessment.reasons,
      canOpen: assessment.canOpen,
      parsed: parsed,
      investigation: assessment.investigation,
    );
  }

  factory ScanRecord.manual({required String rawValue, required String format, required String source}) {
    final DateTime now = DateTime.now();
    final ParsedContent parsed = ContentParserRegistry.instance.parse(rawValue);
    final SecurityAssessment assessment = ScanSecurityAnalyzer.analyze(
      rawValue,
      parsed: parsed,
      analyzedAt: now,
    );
    final String id = sha256.convert(utf8.encode('$rawValue|${now.microsecondsSinceEpoch}')).toString().substring(0, 20);
    return ScanRecord(
      id: id,
      rawValue: rawValue,
      displayValue: rawValue,
      format: format,
      contentType: parsed.title,
      scannedAt: now,
      source: source,
      riskLevel: assessment.level,
      riskReasons: assessment.reasons,
      canOpen: assessment.canOpen,
      parsed: parsed,
      investigation: assessment.investigation,
    );
  }

  static String payloadForBarcode(Barcode barcode) {
    final String text = (barcode.rawValue ?? barcode.displayValue ?? '').trim();
    if (text.isNotEmpty) return text;
    final Uint8List? bytes = _decodedBytes(barcode.rawDecodedBytes);
    if (bytes == null || bytes.isEmpty) return '';
    return 'binary-base64:${base64Encode(bytes)}';
  }

  static Uint8List? _decodedBytes(BarcodeBytes? value) {
    if (value is DecodedBarcodeBytes) return value.bytes;
    if (value is DecodedVisionBarcodeBytes) return value.bytes ?? value.rawBytes;
    return null;
  }

  factory ScanRecord.fromJson(
    Map<String, dynamic> json, {
    bool trustDerivedAnalysis = true,
  }) {
    final String raw = json['rawValue'] as String? ?? '';
    final DateTime scannedAt =
        DateTime.tryParse(json['scannedAt'] as String? ?? '') ?? DateTime.now();
    final ParsedContent parsed = json['parsed'] is Map
        ? ParsedContent.fromJson(Map<String, dynamic>.from(json['parsed'] as Map))
        : ContentParserRegistry.instance.parse(raw);
    final QrInvestigation investigation = trustDerivedAnalysis && json['investigation'] is Map
        ? QrInvestigation.fromJson(Map<String, dynamic>.from(json['investigation'] as Map))
        : ScanSecurityAnalyzer.analyze(
            raw,
            parsed: parsed,
            analyzedAt: scannedAt,
          ).investigation;
    final RiskLevel riskLevel = switch (investigation.severity) {
      QrSeverity.normal => RiskLevel.low,
      QrSeverity.warning => RiskLevel.caution,
      QrSeverity.critical => RiskLevel.high,
    };
    final bool canOpen = investigation.effectiveUri != null &&
        investigation.action != QrActionDecision.block;
    return ScanRecord(
      id: trustDerivedAnalysis
          ? json['id'] as String
          : sha256
              .convert(utf8.encode('$raw|${scannedAt.microsecondsSinceEpoch}'))
              .toString()
              .substring(0, 20),
      rawValue: raw,
      displayValue: json['displayValue'] as String? ?? raw,
      format: json['format'] as String? ?? 'Desconocido',
      contentType: json['contentType'] as String? ?? parsed.title,
      scannedAt: scannedAt,
      source: json['source'] as String? ?? 'Importado',
      riskLevel: riskLevel,
      riskReasons: investigation.findings
          .map((QrFinding item) => QrFindingText.explanation(item.id))
          .toList(growable: false),
      canOpen: canOpen,
      parsed: parsed,
      investigation: investigation,
      favorite: json['favorite'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      notes: json['notes'] as String? ?? '',
    );
  }

  final String id;
  final String rawValue;
  final String displayValue;
  final String format;
  final String contentType;
  final DateTime scannedAt;
  final String source;
  final RiskLevel riskLevel;
  final List<String> riskReasons;
  final bool canOpen;
  final ParsedContent parsed;
  final QrInvestigation investigation;
  final bool favorite;
  final List<String> tags;
  final String notes;

  bool get isSensitive => parsed.sensitive;

  ScanRecord copyWith({bool? favorite, List<String>? tags, String? notes}) => ScanRecord(
        id: id,
        rawValue: rawValue,
        displayValue: displayValue,
        format: format,
        contentType: contentType,
        scannedAt: scannedAt,
        source: source,
        riskLevel: riskLevel,
        riskReasons: riskReasons,
        canOpen: canOpen,
        parsed: parsed,
        investigation: investigation,
        favorite: favorite ?? this.favorite,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'rawValue': rawValue,
        'displayValue': displayValue,
        'format': format,
        'contentType': contentType,
        'scannedAt': scannedAt.toUtc().toIso8601String(),
        'source': source,
        'riskLevel': riskLevel.name,
        'riskReasons': riskReasons,
        'canOpen': canOpen,
        'parsed': parsed.toJson(),
        'investigation': investigation.toJson(),
        'favorite': favorite,
        'tags': tags,
        'notes': notes,
      };
}
