import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_analysis_policy.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/models/parsed_content.dart';

/// Motor local, puro y determinista de observaciones sobre cargas QR.
///
/// No consulta DNS, reputación, certificados ni redirecciones. Separa hechos
/// observados de hipótesis y nunca emite el veredicto "seguro".
abstract final class QrInvestigationEngine {
  static const String engineVersion = '0.1.0';

  static const Set<String> _safeActionSchemes = <String>{
    'mailto',
    'tel',
    'sms',
    'smsto',
    'geo',
  };

  static const Set<String> _shorteners = <String>{
    'bit.ly',
    'bit.do',
    'buff.ly',
    'cutt.ly',
    'goo.gl',
    'is.gd',
    'lnkd.in',
    'ow.ly',
    'rb.gy',
    'rebrand.ly',
    's.id',
    'short.io',
    'shorturl.at',
    't.co',
    'tiny.cc',
    'tiny.one',
    'tinyurl.com',
  };

  static const Set<String> _dangerousExtensions = <String>{
    '.7z',
    '.aab',
    '.apk',
    '.appx',
    '.bat',
    '.cmd',
    '.com',
    '.dmg',
    '.exe',
    '.hta',
    '.iso',
    '.jar',
    '.js',
    '.jse',
    '.lnk',
    '.msi',
    '.pkg',
    '.ps1',
    '.rar',
    '.scr',
    '.vbs',
    '.wsf',
    '.zip',
  };

  static const Set<String> _redirectParameters = <String>{
    'continue',
    'dest',
    'destination',
    'next',
    'r',
    'redirect',
    'redirect_uri',
    'return',
    'return_url',
    'target',
    'u',
    'url',
    'uri',
  };

  static const List<String> limitations = <String>[
    'no-remote-reputation',
    'no-dns-resolution',
    'no-certificate-validation',
    'no-redirect-following',
    'no-domain-age-check',
    'no-visual-sticker-tamper-detection',
    'no-destination-safety-guarantee',
  ];

  /// Analiza una carga y devuelve hechos, hipótesis, decisión y límites.
  ///
  /// Función pura: sin red, sin base de datos, sin Flutter. Las mismas entradas
  /// producen siempre la misma salida, y por eso puede probarse con fixtures
  /// sintéticos y compararse entre versiones.
  ///
  /// Parámetros:
  /// - `rawValue`: la carga tal cual se decodificó. Se hashea sin recortar.
  /// - `parsed`: interpretación previa; aporta el tipo de contenido del que
  ///   dependen `sensitive-secret`, `payment-instruction` y
  ///   `opaque-binary-payload`.
  /// - `policy`: umbrales y marcas de la organización.
  /// - `analyzedAt`: instante fijable para que las pruebas sean deterministas.
  ///
  /// Orden interno del análisis:
  ///
  /// 1. se detecta el esquema declarado y se intenta construir una URI web;
  /// 2. se evalúan las reglas independientes del host (controles invisibles,
  ///    OTP, pago, binario, esquema no permitido);
  /// 3. si hay URI web, se evalúan las reglas de transporte, identidad,
  ///    ofuscación, destino, descarga, credenciales y redirección;
  /// 4. se agregan severidad —máximo— y puntaje —suma acotada a 100—;
  /// 5. se decide la acción y se derivan las hipótesis.
  ///
  /// `forceBlock` se activa solo con condiciones donde la URI no puede
  /// entregarse sin ambigüedad: host vacío, esquema no permitido, caracteres de
  /// control o autoridad ofuscada. Una URL crítica pero interpretable queda en
  /// `confirm`, con su evidencia a la vista.
  ///
  /// Riesgos al modificarla: mover una regla fuera de su bloque cambia qué ids
  /// aparecen en `evaluatedRuleIds`; añadir o cambiar el peso de una sin subir
  /// `engineVersion` rompe la comparabilidad de las evidencias ya exportadas; y
  /// `tool/verify_rootcause_contract.py` falla si el número de reglas deja de
  /// ser 26 o si un id no existe en el esquema, en los textos y en
  /// `docs/rootcause/HEURISTICS.md`.
  static QrInvestigation analyze(
    String rawValue, {
    ParsedContent? parsed,
    QrAnalysisPolicy policy = const QrAnalysisPolicy(),
    DateTime? analyzedAt,
  }) {
    // La carga observada se conserva byte por byte para la huella forense. Solo
    // la copia de trabajo se recorta para que el parser de URI sea tolerante a
    // espacios accidentales alrededor de un código.
    final String value = rawValue.trim();
    final String lower = value.toLowerCase();
    final DateTime timestamp = (analyzedAt ?? DateTime.now()).toUtc();
    final _FindingCollector collector = _FindingCollector();
    final List<String> evaluated = <String>[];

    void evaluate(String id) {
      if (!evaluated.contains(id)) evaluated.add(id);
    }

    void add(
      String id,
      QrSeverity severity,
      int score,
      QrFindingConfidence confidence,
      QrFindingCategory category, [
      List<QrEvidenceFact> evidence = const <QrEvidenceFact>[],
    ]) {
      evaluate(id);
      collector.add(QrFinding(
        id: id,
        severity: severity,
        score: score,
        confidence: confidence,
        category: category,
        evidence: evidence,
      ));
    }

    final String? declaredScheme = _declaredScheme(value);
    final bool safeAction = declaredScheme != null && _safeActionSchemes.contains(declaredScheme);
    final Uri? webUri = _toWebUri(value);
    Uri? effectiveUri = webUri;
    bool forceBlock = false;

    if (safeAction) {
      effectiveUri = Uri.tryParse(value);
    }

    if (declaredScheme != null || webUri != null) {
      evaluate('url-control-character');
      if (_containsControlOrInvisible(rawValue)) {
        add(
          'url-control-character',
          QrSeverity.critical,
          35,
          QrFindingConfidence.high,
          QrFindingCategory.obfuscation,
        );
        forceBlock = true;
      }
    }

    evaluate('sensitive-secret');
    if (parsed?.kind == ContentKind.otp || lower.startsWith('otpauth:')) {
      add(
        'sensitive-secret',
        QrSeverity.warning,
        5,
        QrFindingConfidence.high,
        QrFindingCategory.sensitiveAction,
        const <QrEvidenceFact>[QrEvidenceFact(id: 'contentKind', value: 'otp')],
      );
    }

    evaluate('payment-instruction');
    final bool payment = parsed?.kind == ContentKind.payment ||
        parsed?.kind == ContentKind.crypto ||
        lower.startsWith('bitcoin:') ||
        lower.startsWith('lightning:') ||
        lower.startsWith('ethereum:') ||
        lower.startsWith('000201') ||
        lower.startsWith('spc\n') ||
        lower.startsWith('bcd\n');
    if (payment) {
      add(
        'payment-instruction',
        QrSeverity.warning,
        5,
        QrFindingConfidence.high,
        QrFindingCategory.sensitiveAction,
        <QrEvidenceFact>[
          QrEvidenceFact(id: 'contentKind', value: parsed?.kind.name ?? 'payment'),
        ],
      );
    }

    evaluate('opaque-binary-payload');
    if (parsed?.kind == ContentKind.binary || lower.startsWith('binary-base64:')) {
      add(
        'opaque-binary-payload',
        QrSeverity.warning,
        8,
        QrFindingConfidence.high,
        QrFindingCategory.obfuscation,
      );
    }

    if (webUri == null && !safeAction) {
      evaluate('scheme-blocked');
      if (declaredScheme != null && !_isKnownStructuredScheme(declaredScheme)) {
        add(
          'scheme-blocked',
          QrSeverity.critical,
          35,
          QrFindingConfidence.high,
          QrFindingCategory.destination,
          <QrEvidenceFact>[QrEvidenceFact(id: 'scheme', value: declaredScheme)],
        );
        forceBlock = true;
      }
    }

    String? host;
    if (webUri != null) {
      final String webHost = webUri.host.toLowerCase();
      host = webHost;
      final String authority = _rawAuthority(value);
      final String authorityLower = authority.toLowerCase();
      final String decodedPath = _safeDecode(webUri.path).toLowerCase();

      evaluate('host-empty');
      if (webHost.isEmpty) {
        add(
          'host-empty',
          QrSeverity.critical,
          40,
          QrFindingConfidence.high,
          QrFindingCategory.destination,
        );
        forceBlock = true;
      }

      evaluate('transport-http');
      if (webUri.scheme == 'http') {
        add(
          'transport-http',
          QrSeverity.warning,
          8,
          QrFindingConfidence.high,
          QrFindingCategory.transport,
          const <QrEvidenceFact>[QrEvidenceFact(id: 'scheme', value: 'http')],
        );
      }

      evaluate('authority-userinfo');
      if (webUri.userInfo.isNotEmpty || authority.contains('@')) {
        add(
          'authority-userinfo',
          QrSeverity.critical,
          25,
          QrFindingConfidence.high,
          QrFindingCategory.obfuscation,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      evaluate('host-punycode');
      if (webHost.split('.').any((String label) => label.startsWith('xn--'))) {
        add(
          'host-punycode',
          QrSeverity.critical,
          20,
          QrFindingConfidence.medium,
          QrFindingCategory.identity,
          <QrEvidenceFact>[QrEvidenceFact(id: 'normalizedHost', value: webHost)],
        );
      }

      evaluate('host-mixed-script');
      if (_hasMixedScripts(webHost)) {
        add(
          'host-mixed-script',
          QrSeverity.critical,
          25,
          QrFindingConfidence.high,
          QrFindingCategory.identity,
          <QrEvidenceFact>[QrEvidenceFact(id: 'normalizedHost', value: webHost)],
        );
      }

      evaluate('host-unicode');
      if (webHost.runes.any((int rune) => rune > 127)) {
        add(
          'host-unicode',
          QrSeverity.warning,
          5,
          QrFindingConfidence.low,
          QrFindingCategory.identity,
          <QrEvidenceFact>[QrEvidenceFact(id: 'normalizedHost', value: webHost)],
        );
      }

      evaluate('host-ip-literal');
      if (_isIpAddress(webHost)) {
        add(
          'host-ip-literal',
          QrSeverity.warning,
          8,
          QrFindingConfidence.high,
          QrFindingCategory.identity,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      evaluate('host-private-or-local');
      if (!policy.allowPrivateTargets && _isPrivateOrLocalHost(webHost)) {
        add(
          'host-private-or-local',
          QrSeverity.critical,
          20,
          QrFindingConfidence.high,
          QrFindingCategory.destination,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      evaluate('host-shortener');
      if (_shorteners.any((String item) => _hostMatches(webHost, item))) {
        add(
          'host-shortener',
          QrSeverity.warning,
          10,
          QrFindingConfidence.high,
          QrFindingCategory.redirect,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      final int domainLabels = webHost.isEmpty ? 0 : webHost.split('.').length;
      evaluate('host-deep-subdomains');
      if (domainLabels > policy.maxDomainLabels) {
        add(
          'host-deep-subdomains',
          QrSeverity.warning,
          5,
          QrFindingConfidence.medium,
          QrFindingCategory.identity,
          <QrEvidenceFact>[QrEvidenceFact(id: 'subdomainLabels', value: '$domainLabels')],
        );
      }

      evaluate('host-trailing-dot');
      if (authorityLower.split('@').last.split(':').first.endsWith('.')) {
        add(
          'host-trailing-dot',
          QrSeverity.warning,
          3,
          QrFindingConfidence.medium,
          QrFindingCategory.obfuscation,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      final int hyphens = webHost.runes.where((int rune) => rune == 0x2D).length;
      evaluate('host-hyphen-density');
      if (hyphens >= 4 || webHost.split('.').any((String label) => '-'.allMatches(label).length >= 3)) {
        add(
          'host-hyphen-density',
          QrSeverity.warning,
          3,
          QrFindingConfidence.low,
          QrFindingCategory.identity,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      evaluate('port-unusual');
      final int port = webUri.hasPort ? webUri.port : (webUri.scheme == 'https' ? 443 : 80);
      if (webUri.hasPort && !const <int>{80, 443}.contains(port)) {
        add(
          'port-unusual',
          QrSeverity.warning,
          6,
          QrFindingConfidence.high,
          QrFindingCategory.destination,
          <QrEvidenceFact>[QrEvidenceFact(id: 'port', value: '$port')],
        );
      }

      evaluate('url-excessive-length');
      if (rawValue.length > policy.maxUrlLength) {
        add(
          'url-excessive-length',
          QrSeverity.warning,
          4,
          QrFindingConfidence.medium,
          QrFindingCategory.obfuscation,
          <QrEvidenceFact>[QrEvidenceFact(id: 'length', value: '${rawValue.length}')],
        );
      }

      evaluate('authority-obfuscated');
      if (authority.contains('\\') ||
          authority.runes.any((int rune) => rune <= 0x20) ||
          '@'.allMatches(authority).length > 1) {
        add(
          'authority-obfuscated',
          QrSeverity.critical,
          30,
          QrFindingConfidence.high,
          QrFindingCategory.obfuscation,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
        forceBlock = true;
      }

      evaluate('encoded-separator');
      if (<String>['%2f', '%5c', '%40', '%3a', '%252f', '%255c', '%2540']
          .any(authorityLower.contains)) {
        add(
          'encoded-separator',
          QrSeverity.critical,
          20,
          QrFindingConfidence.high,
          QrFindingCategory.obfuscation,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      evaluate('download-dangerous-extension');
      String? extension;
      for (final String candidate in _dangerousExtensions) {
        if (decodedPath.endsWith(candidate)) {
          extension = candidate;
          break;
        }
      }
      if (extension != null) {
        add(
          'download-dangerous-extension',
          QrSeverity.critical,
          25,
          QrFindingConfidence.high,
          QrFindingCategory.download,
          <QrEvidenceFact>[QrEvidenceFact(id: 'extension', value: extension)],
        );
      }

      evaluate('credential-lure-path');
      if (_looksLikeCredentialLure(webUri)) {
        add(
          'credential-lure-path',
          QrSeverity.warning,
          8,
          QrFindingConfidence.medium,
          QrFindingCategory.credential,
          <QrEvidenceFact>[QrEvidenceFact(id: 'host', value: webHost)],
        );
      }

      evaluate('tracking-excessive');
      final List<String> trackers = webUri.queryParameters.keys.where((String key) {
        final String normalized = key.toLowerCase();
        return normalized.startsWith('utm_') ||
            const <String>{'gclid', 'fbclid', 'mc_cid', 'mc_eid', 'ref'}.contains(normalized);
      }).toList(growable: false);
      if (trackers.length >= 3) {
        add(
          'tracking-excessive',
          QrSeverity.warning,
          3,
          QrFindingConfidence.high,
          QrFindingCategory.obfuscation,
          <QrEvidenceFact>[QrEvidenceFact(id: 'trackingParameters', value: trackers.join(','))],
        );
      }

      evaluate('redirect-nested-domain');
      final _NestedRedirect? nested = _nestedRedirect(webUri, webHost);
      if (nested != null) {
        add(
          'redirect-nested-domain',
          QrSeverity.critical,
          20,
          QrFindingConfidence.high,
          QrFindingCategory.redirect,
          <QrEvidenceFact>[
            QrEvidenceFact(id: 'redirectParameter', value: nested.parameter),
            QrEvidenceFact(id: 'redirectHost', value: nested.host),
          ],
        );
      }

      evaluate('brand-domain-mismatch');
      final _BrandMismatch? brand = _brandMismatch(webUri, policy.trustedBrands);
      if (brand != null) {
        add(
          'brand-domain-mismatch',
          QrSeverity.critical,
          30,
          QrFindingConfidence.high,
          QrFindingCategory.identity,
          <QrEvidenceFact>[
            QrEvidenceFact(id: 'brandId', value: brand.brandId),
            QrEvidenceFact(id: 'token', value: brand.token),
            QrEvidenceFact(id: 'host', value: webHost),
          ],
        );
      }
    }

    final List<QrFinding> findings = collector.findings;
    final QrSeverity severity = findings.any((QrFinding item) => item.severity == QrSeverity.critical)
        ? QrSeverity.critical
        : findings.any((QrFinding item) => item.severity == QrSeverity.warning)
            ? QrSeverity.warning
            : QrSeverity.normal;
    final int score = findings
        .fold<int>(0, (int total, QrFinding item) => total + item.score)
        .clamp(0, 100)
        .toInt();

    final QrActionDecision action;
    if (forceBlock) {
      action = QrActionDecision.block;
    } else if (webUri != null) {
      action = findings.isEmpty ? QrActionDecision.allow : QrActionDecision.confirm;
    } else if (safeAction) {
      action = QrActionDecision.confirm;
    } else {
      action = QrActionDecision.inspectOnly;
    }

    final Set<String> ids = findings.map((QrFinding item) => item.id).toSet();
    final List<String> hypotheses = <String>[];
    const Set<String> phishingSignals = <String>{
      'authority-userinfo',
      'brand-domain-mismatch',
      'host-mixed-script',
      'host-punycode',
      'host-shortener',
      'redirect-nested-domain',
    };
    if (ids.any(phishingSignals.contains)) hypotheses.add('qr-phishing-suspected');
    if (ids.contains('credential-lure-path') && ids.any(phishingSignals.contains)) {
      hypotheses.add('credential-theft-suspected');
    }
    if (ids.contains('download-dangerous-extension')) hypotheses.add('malware-delivery-suspected');
    if (ids.contains('payment-instruction')) hypotheses.add('payment-substitution-review');
    if (ids.contains('host-private-or-local')) hypotheses.add('local-network-lure');
    if (ids.contains('scheme-blocked')) hypotheses.add('unsafe-uri-execution');

    return QrInvestigation(
      engineVersion: engineVersion,
      analyzedAt: timestamp,
      payloadSha256: sha256.convert(utf8.encode(rawValue)).toString(),
      severity: severity,
      score: score,
      action: action,
      normalizedHost: host,
      effectiveUri: effectiveUri?.toString(),
      findings: findings,
      hypotheses: hypotheses,
      evaluatedRuleIds: List<String>.unmodifiable(evaluated),
      limitations: limitations,
    );
  }

  static bool _isKnownStructuredScheme(String scheme) => const <String>{
        'begin',
        'binary-base64',
        'bitcoin',
        'ethereum',
        'lightning',
        'matmsg',
        'mecard',
        'otpauth',
        'wifi',
      }.contains(scheme);

  static String? _declaredScheme(String value) {
    final RegExpMatch? match = RegExp(r'^([a-z][a-z0-9+.-]*):', caseSensitive: false).firstMatch(value);
    return match?.group(1)?.toLowerCase();
  }

  static Uri? _toWebUri(String value) {
    final String normalized = value.toLowerCase().startsWith('www.') ? 'https://$value' : value;
    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null || !const <String>{'http', 'https'}.contains(uri.scheme.toLowerCase())) return null;
    return uri;
  }

  static String _rawAuthority(String value) {
    final int start = value.indexOf('://');
    if (start < 0) return '';
    final String remaining = value.substring(start + 3);
    final int end = remaining.indexOf(RegExp(r'[/#?]'));
    return end < 0 ? remaining : remaining.substring(0, end);
  }

  static bool _hostMatches(String host, String expected) =>
      host == expected || host.endsWith('.$expected');

  static bool _isIpAddress(String host) {
    final RegExp ipv4 = RegExp(r'^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$');
    return ipv4.hasMatch(host) || host.contains(':');
  }

  static bool _isPrivateOrLocalHost(String host) {
    final String h = host.toLowerCase();
    if (h == 'localhost' || h.endsWith('.localhost') || h.endsWith('.local') || h.endsWith('.internal')) {
      return true;
    }
    if (h.contains(':') &&
        (h == '::1' ||
            h.startsWith('fc') ||
            h.startsWith('fd') ||
            h.startsWith('fe80:'))) {
      return true;
    }
    final List<int?> parsed = h.split('.').map(int.tryParse).toList(growable: false);
    if (parsed.length != 4 || parsed.any((int? value) => value == null)) return false;
    final List<int> parts = parsed.cast<int>();
    return parts[0] == 0 ||
        parts[0] == 10 ||
        parts[0] == 127 ||
        (parts[0] == 192 && parts[1] == 168) ||
        (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) ||
        (parts[0] == 169 && parts[1] == 254);
  }

  static bool _hasMixedScripts(String host) {
    bool latin = false;
    bool cyrillic = false;
    bool greek = false;
    for (final int rune in host.runes) {
      if (rune >= 0x0041 && rune <= 0x024F) latin = true;
      if (rune >= 0x0400 && rune <= 0x052F) cyrillic = true;
      if (rune >= 0x0370 && rune <= 0x03FF) greek = true;
    }
    return <bool>[latin, cyrillic, greek].where((bool value) => value).length > 1;
  }

  static bool _containsControlOrInvisible(String value) {
    final String lower = value.toLowerCase();
    if (RegExp(r'%(?:0[0-9a-f]|1[0-9a-f]|7f)').hasMatch(lower) ||
        lower.contains('%e2%80%8b') ||
        lower.contains('%ef%bb%bf')) {
      return true;
    }
    return value.runes.any((int rune) =>
        rune < 0x20 ||
        rune == 0x7F ||
        rune == 0x200B ||
        rune == 0x200C ||
        rune == 0x200D ||
        rune == 0xFEFF ||
        (rune >= 0x202A && rune <= 0x202E) ||
        (rune >= 0x2066 && rune <= 0x2069));
  }

  static String _safeDecode(String value) {
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      return value;
    }
  }

  static bool _looksLikeCredentialLure(Uri uri) {
    final String value = '${uri.path}?${uri.query}'.toLowerCase();
    return const <String>[
      'access',
      'account',
      'auth',
      'banco',
      'bank',
      'clave',
      'cuenta',
      'credential',
      'login',
      'mfa',
      'oauth',
      'password',
      'reset',
      'secure',
      'sesion',
      'signin',
      'sso',
      'token',
      'unlock',
      'validar',
      'verification',
      'verify',
      'wallet',
    ].any(value.contains);
  }

  static _NestedRedirect? _nestedRedirect(Uri uri, String visibleHost) {
    for (final MapEntry<String, String> entry in uri.queryParameters.entries) {
      final String key = entry.key.toLowerCase();
      if (!_redirectParameters.contains(key)) continue;
      final String candidate = entry.value.startsWith('//') ? '${uri.scheme}:${entry.value}' : entry.value;
      final Uri? nested = _toWebUri(candidate);
      if (nested == null || nested.host.isEmpty) continue;
      final String nestedHost = nested.host.toLowerCase();
      if (!_sameHostFamily(visibleHost, nestedHost)) {
        return _NestedRedirect(parameter: entry.key, host: nestedHost);
      }
    }
    return null;
  }

  static bool _sameHostFamily(String first, String second) =>
      first == second || first.endsWith('.$second') || second.endsWith('.$first');

  static _BrandMismatch? _brandMismatch(Uri uri, List<QrTrustedBrand> brands) {
    if (brands.isEmpty || uri.host.isEmpty) return null;
    final String host = uri.host.toLowerCase();
    final String comparable = _comparable('$host${uri.path}');
    for (final QrTrustedBrand brand in brands) {
      final bool allowed = brand.allowedHosts
          .map((String item) => item.toLowerCase().trim())
          .where((String item) => item.isNotEmpty)
          .any((String item) => _hostMatches(host, item));
      if (allowed) continue;
      for (final String rawToken in brand.tokens) {
        final String token = _comparable(rawToken);
        if (token.length >= 4 && comparable.contains(token)) {
          return _BrandMismatch(brandId: brand.id, token: rawToken);
        }
      }
    }
    return null;
  }

  static String _comparable(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _FindingCollector {
  final List<QrFinding> _findings = <QrFinding>[];
  final Set<String> _ids = <String>{};

  List<QrFinding> get findings => List<QrFinding>.unmodifiable(_findings);

  void add(QrFinding finding) {
    if (_ids.add(finding.id)) _findings.add(finding);
  }
}

class _NestedRedirect {
  const _NestedRedirect({required this.parameter, required this.host});
  final String parameter;
  final String host;
}

class _BrandMismatch {
  const _BrandMismatch({required this.brandId, required this.token});
  final String brandId;
  final String token;
}
