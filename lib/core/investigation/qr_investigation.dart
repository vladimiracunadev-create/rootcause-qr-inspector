/// Contrato de investigación de RootCause QR Inspector.
///
/// El núcleo usa identificadores estables y neutrales al idioma. La UI traduce
/// esos identificadores; el JSON forense conserva los ids y la evidencia cruda
/// para poder comparar resultados entre versiones y superficies RootCause.
library;

/// Gravedad de un hallazgo y, por agregación, de toda la investigación.
///
/// La severidad global es el **máximo** de las severidades observadas; no se
/// deduce del puntaje. `normal` significa «ninguna regla aplicable disparó»,
/// nunca «destino seguro».
enum QrSeverity { normal, warning, critical }

/// Cuánta confianza merece la observación por sí sola.
///
/// Una confianza baja indica que el hecho es cierto pero admite explicaciones
/// legítimas frecuentes: un dominio internacional válido dispara
/// `host-unicode` sin que exista ningún engaño.
enum QrFindingConfidence { low, medium, high }

/// Familia del hallazgo, usada para agrupar y para el mapeo a otros productos.
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

/// Política local de entrega de la carga a otra aplicación.
///
/// - `allow`: la URI es interpretable y ninguna regla aplicable disparó.
/// - `confirm`: es interpretable, pero exige una decisión humana explícita.
/// - `inspectOnly`: el contenido se explica, pero no hay acción externa segura.
/// - `block`: la semántica de ejecución es inválida, desconocida o ambigua.
///
/// `block` no significa «malicioso», sino que el sistema no puede delegar la
/// acción sin riesgo de que otra aplicación la interprete distinto. `allow` no
/// significa «seguro».
enum QrActionDecision { allow, confirm, inspectOnly, block }

/// Hecho mínimo que sustenta un hallazgo: par id/valor neutral al idioma.
///
/// El id se traduce en la interfaz con `QrFindingText.evidenceLabel`; el JSON
/// forense conserva el id crudo para poder compararse entre versiones.
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

/// Una propiedad observada en la carga, no una acusación.
///
/// [id] es estable y no depende del idioma; cambiar su condición o su [score]
/// obliga a subir `QrInvestigationEngine.engineVersion`, porque de lo
/// contrario dos exportaciones con la misma versión dejarían de ser
/// comparables.
///
/// [score] es un peso declarado que ordena evidencia; no es una probabilidad
/// de fraude.
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

/// Resultado completo y serializable de analizar una carga.
///
/// Separa deliberadamente cuatro cosas que suelen confundirse:
///
/// - [findings]: hechos observados, con su evidencia;
/// - [hypotheses]: explicaciones que requieren investigación humana y que
///   **no** suman puntos;
/// - `severity`/`score`/`action`: el veredicto operativo;
/// - [limitations]: lo que este análisis no pudo comprobar, y que nunca debe
///   interpretarse como «sin riesgo».
///
/// [payloadSha256] cubre la carga **exacta**, incluidos espacios y controles
/// alrededor: dos códigos que se ven iguales pero difieren en un byte
/// invisible producen huellas distintas, que es justo lo que una investigación
/// necesita distinguir.
///
/// [evaluatedRuleIds] lista las reglas que llegaron a evaluarse, no solo las
/// que dispararon: permite saber si una regla no aplicó o no se ejecutó.
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
