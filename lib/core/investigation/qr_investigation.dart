/// Contrato de investigación de RootCause QR Inspector.
///
/// El núcleo usa identificadores estables y neutrales al idioma. La UI traduce
/// esos identificadores; el JSON forense conserva los ids y la evidencia cruda
/// para poder comparar resultados entre versiones y superficies RootCause.
library;

enum QrSeverity { normal, warning, critical }

enum QrFindingConfidence { low, medium, high }

enum QrFindingCategory {
  transport,
  identity,
  obfuscation,
  destination,
  credential,
  download,
  redirect,
  sensitiveAction,
}

enum QrActionDecision { allow, confirm, inspectOnly, block }

class QrEvidenceFact {
  const QrEvidenceFact({required this.id, required this.value});

  final String id;
  final String value;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'value': value,
      };

  factory QrEvidenceFact.fromJson(Map<String, dynamic> json) => QrEvidenceFact(
        id: json['id'] as String? ?? 'unknown',
        value: json['value'] as String? ?? '',
      );
}

class QrFinding {
  const QrFinding({
    required this.id,
    required this.severity,
    required this.score,
    required this.confidence,
    required this.category,
    this.evidence = const <QrEvidenceFact>[],
  });

  final String id;
  final QrSeverity severity;
  final int score;
  final QrFindingConfidence confidence;
  final QrFindingCategory category;
  final List<QrEvidenceFact> evidence;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'severity': severity.name,
        'score': score,
        'confidence': confidence.name,
        'category': category.name,
        'evidence': evidence.map((QrEvidenceFact item) => item.toJson()).toList(growable: false),
      };

  factory QrFinding.fromJson(Map<String, dynamic> json) => QrFinding(
        id: json['id'] as String? ?? 'unknown',
        severity: _enumByName(QrSeverity.values, json['severity'], QrSeverity.warning),
        score: (json['score'] as num?)?.toInt() ?? 0,
        confidence: _enumByName(
          QrFindingConfidence.values,
          json['confidence'],
          QrFindingConfidence.low,
        ),
        category: _enumByName(
          QrFindingCategory.values,
          json['category'],
          QrFindingCategory.destination,
        ),
        evidence: (json['evidence'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map item) => QrEvidenceFact.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
}

class QrInvestigation {
  const QrInvestigation({
    required this.engineVersion,
    required this.analyzedAt,
    required this.payloadSha256,
    required this.severity,
    required this.score,
    required this.action,
    required this.findings,
    required this.hypotheses,
    required this.evaluatedRuleIds,
    required this.limitations,
    this.normalizedHost,
    this.effectiveUri,
  });

  static const String schema = 'rootcause.qr-investigation.v1';

  final String engineVersion;
  final DateTime analyzedAt;
  final String payloadSha256;
  final QrSeverity severity;
  final int score;
  final QrActionDecision action;
  final String? normalizedHost;
  final String? effectiveUri;
  final List<QrFinding> findings;
  final List<String> hypotheses;
  final List<String> evaluatedRuleIds;
  final List<String> limitations;

  bool get hasSignals => findings.isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'schema': schema,
        'engineVersion': engineVersion,
        'analyzedAt': analyzedAt.toUtc().toIso8601String(),
        'payloadSha256': payloadSha256,
        'verdict': <String, Object?>{
          'severity': severity.name,
          'score': score,
          'action': action.name,
        },
        if (normalizedHost != null) 'normalizedHost': normalizedHost,
        if (effectiveUri != null) 'effectiveUri': effectiveUri,
        'findings': findings.map((QrFinding item) => item.toJson()).toList(growable: false),
        'hypotheses': hypotheses,
        'evaluatedRuleIds': evaluatedRuleIds,
        'limitations': limitations,
      };

  factory QrInvestigation.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> verdict =
        Map<String, dynamic>.from(json['verdict'] as Map? ?? const <String, dynamic>{});
    return QrInvestigation(
      engineVersion: json['engineVersion'] as String? ?? 'unknown',
      analyzedAt: DateTime.tryParse(json['analyzedAt'] as String? ?? '') ?? DateTime.now().toUtc(),
      payloadSha256: json['payloadSha256'] as String? ?? '',
      severity: _enumByName(QrSeverity.values, verdict['severity'], QrSeverity.warning),
      score: (verdict['score'] as num?)?.toInt() ?? 0,
      action: _enumByName(
        QrActionDecision.values,
        verdict['action'],
        QrActionDecision.inspectOnly,
      ),
      normalizedHost: json['normalizedHost'] as String?,
      effectiveUri: json['effectiveUri'] as String?,
      findings: (json['findings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map item) => QrFinding.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      hypotheses: (json['hypotheses'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(growable: false),
      evaluatedRuleIds:
          (json['evaluatedRuleIds'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(growable: false),
      limitations: (json['limitations'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(growable: false),
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final String name = raw is String ? raw : '';
  for (final T value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
