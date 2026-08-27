/// Familia de contenido que el intérprete reconoció dentro de la carga.
///
/// El valor viaja al motor de reglas —`sensitive-secret`, `payment-instruction`
/// y `opaque-binary-payload` se derivan de él— y también decide qué registros
/// quedan fuera del historial automático. Añadir un valor obliga a revisar
/// `ContentInterpreter`, `QrInvestigationEngine` y `ScanResultsSheet`.
enum ContentKind {
  url,
  wifi,
  contact,
  event,
  email,
  phone,
  sms,
  geo,
  otp,
  gs1,
  isbn,
  product,
  payment,
  crypto,
  identity,
  binary,
  text,
}

/// Resultado inmutable de interpretar una carga cruda.
///
/// Es un dato de presentación y de entrada al motor, nunca un veredicto:
/// describe qué campos se pudieron leer, no si el contenido es legítimo.
///
/// - [kind] decide iconografía, acción sugerida y reglas dependientes del tipo.
/// - [title] y [summary] son textos en español para la interfaz.
/// - [fields] conserva pares etiqueta/valor ya legibles por una persona.
/// - [sensitive] marca material que no debe persistirse automáticamente
///   (OTP, Wi-Fi con contraseña, pagos, identidad o URL con token). El
///   escáner consulta esta bandera antes de guardar en el historial.
///
/// `toJson`/`fromJson` son simétricos y toleran un respaldo incompleto: cada
/// campo ausente cae en un valor por defecto en vez de lanzar.
class ParsedContent {
  const ParsedContent({
    required this.kind,
    required this.title,
    required this.fields,
    this.summary,
    this.sensitive = false,
  });

  final ContentKind kind;
  final String title;
  final String? summary;
  final Map<String, String> fields;
  final bool sensitive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'title': title,
        'summary': summary,
        'fields': fields,
        'sensitive': sensitive,
      };

  factory ParsedContent.fromJson(Map<String, dynamic> json) {
    return ParsedContent(
      kind: ContentKind.values.byName(json['kind'] as String? ?? 'text'),
      title: json['title'] as String? ?? 'Texto',
      summary: json['summary'] as String?,
      fields: Map<String, dynamic>.from(json['fields'] as Map? ?? const <String, dynamic>{})
          .map((String key, dynamic value) => MapEntry<String, String>(key, '$value')),
      sensitive: json['sensitive'] as bool? ?? false,
    );
  }
}
