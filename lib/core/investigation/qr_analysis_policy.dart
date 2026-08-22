class QrTrustedBrand {
  const QrTrustedBrand({
    required this.id,
    required this.tokens,
    required this.allowedHosts,
  });

  final String id;
  final List<String> tokens;
  final List<String> allowedHosts;

  factory QrTrustedBrand.fromJson(Map<String, dynamic> json) => QrTrustedBrand(
        id: json['id'] as String? ?? 'unknown',
        tokens: (json['tokens'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(growable: false),
        allowedHosts:
            (json['allowedHosts'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(growable: false),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'tokens': tokens,
        'allowedHosts': allowedHosts,
      };
}

class QrAnalysisPolicy {
  const QrAnalysisPolicy({
    this.maxUrlLength = 240,
    this.maxDomainLabels = 5,
    this.allowPrivateTargets = false,
    this.trustedBrands = const <QrTrustedBrand>[],
  });

  final int maxUrlLength;
  final int maxDomainLabels;
  final bool allowPrivateTargets;
  final List<QrTrustedBrand> trustedBrands;

  factory QrAnalysisPolicy.fromJson(Map<String, dynamic> json) => QrAnalysisPolicy(
        maxUrlLength: (json['maxUrlLength'] as num?)?.toInt() ?? 240,
        maxDomainLabels: (json['maxDomainLabels'] as num?)?.toInt() ?? 5,
        allowPrivateTargets: json['allowPrivateTargets'] as bool? ?? false,
        trustedBrands: (json['trustedBrands'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map item) => QrTrustedBrand.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schema': 'rootcause.qr-policy.v1',
        'maxUrlLength': maxUrlLength,
        'maxDomainLabels': maxDomainLabels,
        'allowPrivateTargets': allowPrivateTargets,
        'trustedBrands': trustedBrands.map((QrTrustedBrand item) => item.toJson()).toList(growable: false),
      };
}
