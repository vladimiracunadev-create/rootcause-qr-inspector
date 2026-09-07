import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/models/parsed_content.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

/// Human-facing projection of the existing scan contracts.
///
/// This object owns no analysis. It derives every value from [ScanRecord],
/// [ParsedContent], and [QrInvestigation], which remain the sources of truth.
class ResolvedScanTarget {
  const ResolvedScanTarget({
    required this.kind,
    required this.title,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryValues,
    required this.actionable,
    required this.sensitive,
    required this.requiresConfirmation,
    required this.blocked,
    required this.source,
    required this.barcodeFormat,
    this.effectiveUri,
    this.normalizedHost,
  });

  factory ResolvedScanTarget.fromRecord(ScanRecord record) {
    final ParsedContent parsed = record.parsed;
    final QrInvestigation investigation = record.investigation;
    final (String, String) primary = _primary(parsed, record.rawValue);
    return ResolvedScanTarget(
      kind: parsed.kind,
      title: _targetTitle(parsed.kind),
      primaryLabel: primary.$1,
      primaryValue: primary.$2,
      secondaryValues: Map<String, String>.unmodifiable(parsed.fields),
      effectiveUri: investigation.effectiveUri,
      normalizedHost: investigation.normalizedHost,
      actionable:
          investigation.effectiveUri != null &&
          investigation.action != QrActionDecision.inspectOnly &&
          investigation.action != QrActionDecision.block,
      sensitive: record.isSensitive,
      requiresConfirmation: investigation.action == QrActionDecision.confirm,
      blocked: investigation.action == QrActionDecision.block,
      source: record.source,
      barcodeFormat: record.format,
    );
  }

  final ContentKind kind;
  final String title;
  final String primaryLabel;
  final String primaryValue;
  final Map<String, String> secondaryValues;
  final String? effectiveUri;
  final String? normalizedHost;
  final bool actionable;
  final bool sensitive;
  final bool requiresConfirmation;
  final bool blocked;
  final String source;
  final String barcodeFormat;

  static String _targetTitle(ContentKind kind) => switch (kind) {
    ContentKind.url => 'Destino web',
    ContentKind.email => 'Acción de correo',
    ContentKind.phone => 'Número de teléfono',
    ContentKind.sms => 'Mensaje de texto',
    ContentKind.geo => 'Ubicación',
    ContentKind.wifi => 'Red Wi-Fi',
    ContentKind.contact => 'Persona o contacto',
    ContentKind.event => 'Evento',
    ContentKind.otp => 'Configuración OTP sensible',
    ContentKind.payment => 'Instrucción de pago',
    ContentKind.crypto => 'Dirección de criptoactivo',
    ContentKind.gs1 ||
    ContentKind.isbn ||
    ContentKind.product => 'Identificador de producto',
    ContentKind.identity => 'Información de identificación',
    ContentKind.binary => 'Contenido binario no interpretable',
    ContentKind.text => 'Texto sin acción externa',
  };

  static (String, String) _primary(ParsedContent parsed, String rawValue) {
    final Map<String, String> fields = parsed.fields;
    return switch (parsed.kind) {
      ContentKind.url => (
        'Destino codificado',
        fields['Dirección'] ?? rawValue,
      ),
      ContentKind.email => ('Destinatario', fields['Destinatario'] ?? rawValue),
      ContentKind.phone => ('Número', fields['Número'] ?? rawValue),
      ContentKind.sms => ('Número', fields['Número'] ?? rawValue),
      ContentKind.geo => (
        'Coordenadas',
        '${fields['Latitud'] ?? ''}, ${fields['Longitud'] ?? ''}'.trim(),
      ),
      ContentKind.wifi => ('Red', fields['Red'] ?? parsed.summary ?? ''),
      ContentKind.contact => (
        'Contacto',
        fields['Nombre'] ?? parsed.summary ?? rawValue,
      ),
      ContentKind.event => (
        'Evento',
        fields['Título'] ?? parsed.summary ?? rawValue,
      ),
      ContentKind.otp => (
        'Cuenta OTP',
        fields['Cuenta'] ?? parsed.summary ?? 'Configuración protegida',
      ),
      ContentKind.payment => (
        'Pago',
        fields['Beneficiario'] ?? fields['Comercio'] ?? parsed.title,
      ),
      ContentKind.crypto => ('Dirección', fields['Dirección'] ?? rawValue),
      ContentKind.gs1 => ('Identificador', fields['GTIN'] ?? rawValue),
      ContentKind.isbn => ('ISBN', fields['ISBN'] ?? rawValue),
      ContentKind.product => (
        'Identificador',
        fields['Identificador'] ?? rawValue,
      ),
      ContentKind.identity => (
        'Identificación',
        fields['Número de licencia'] ?? parsed.title,
      ),
      ContentKind.binary => ('Contenido', 'Datos binarios; no se ejecutarán'),
      ContentKind.text => ('Contenido', fields['Contenido'] ?? rawValue),
    };
  }
}
