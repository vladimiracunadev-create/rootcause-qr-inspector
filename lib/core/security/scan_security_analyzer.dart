import 'package:rootcause_qr_inspector/core/investigation/qr_analysis_policy.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_finding_text.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation_engine.dart';
import 'package:rootcause_qr_inspector/models/parsed_content.dart';

/// Adaptador de compatibilidad para las pantallas heredadas del lector.
///
/// La fuente de verdad es [QrInvestigation]. `RiskLevel` se conserva para no
/// romper filtros, importaciones y widgets de RootCause QR Inspector.
enum RiskLevel { low, caution, high }

class SecurityAssessment {
  const SecurityAssessment({
    required this.level,
    required this.reasons,
    required this.canOpen,
    required this.investigation,
    this.normalizedHost,
  });

  final RiskLevel level;
  final List<String> reasons;
  final bool canOpen;
  final QrInvestigation investigation;
  final String? normalizedHost;

  String get label => switch (level) {
        RiskLevel.low => 'Sin señales locales observadas',
        RiskLevel.caution => 'Revisar antes de actuar',
        RiskLevel.high => 'Señales críticas observadas',
      };
}

abstract final class ScanSecurityAnalyzer {
  static SecurityAssessment analyze(
    String rawValue, {
    ParsedContent? parsed,
    QrAnalysisPolicy policy = const QrAnalysisPolicy(),
    DateTime? analyzedAt,
  }) {
    final QrInvestigation investigation = QrInvestigationEngine.analyze(
      rawValue,
      parsed: parsed,
      policy: policy,
      analyzedAt: analyzedAt,
    );
    final RiskLevel level = switch (investigation.severity) {
      QrSeverity.normal => RiskLevel.low,
      QrSeverity.warning => RiskLevel.caution,
      QrSeverity.critical => RiskLevel.high,
    };
    final Uri? action = investigation.effectiveUri == null
        ? null
        : Uri.tryParse(investigation.effectiveUri!);
    return SecurityAssessment(
      level: level,
      reasons: investigation.findings
          .map((QrFinding item) => QrFindingText.explanation(item.id))
          .toList(growable: false),
      canOpen: action != null && investigation.action != QrActionDecision.block,
      investigation: investigation,
      normalizedHost: investigation.normalizedHost,
    );
  }

  static Uri? normalizedActionUri(String rawValue) {
    final String value = rawValue.trim();
    final String lower = value.toLowerCase();
    if (<String>['mailto:', 'tel:', 'sms:', 'smsto:', 'geo:'].any(lower.startsWith)) {
      return Uri.tryParse(value);
    }
    final String normalized = lower.startsWith('www.') ? 'https://$value' : value;
    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null || !const <String>{'http', 'https'}.contains(uri.scheme)) return null;
    return uri;
  }
}
