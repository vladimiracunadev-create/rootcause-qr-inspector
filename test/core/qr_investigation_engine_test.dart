import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_analysis_policy.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation_engine.dart';
import 'package:rootcause_qr_inspector/services/content_interpreter.dart';

void main() {
  QrInvestigation analyze(
    String value, {
    QrAnalysisPolicy policy = const QrAnalysisPolicy(),
  }) =>
      QrInvestigationEngine.analyze(
        value,
        parsed: ContentInterpreter.parse(value),
        policy: policy,
        analyzedAt: DateTime.utc(2026, 8, 20),
      );

  group('QrInvestigationEngine', () {
    test('un HTTPS común queda normal, pero conserva límites explícitos', () {
      final QrInvestigation result = analyze('https://example.com/documento');

      expect(result.severity, QrSeverity.normal);
      expect(result.score, 0);
      expect(result.action, QrActionDecision.allow);
      expect(result.findings, isEmpty);
      expect(result.limitations, contains('no-destination-safety-guarantee'));
    });

    test('la huella cubre la carga exacta aunque el parser recorte bordes', () {
      final QrInvestigation plain = analyze('https://example.com/documento');
      final QrInvestigation padded = analyze('\nhttps://example.com/documento\n');

      expect(padded.normalizedHost, plain.normalizedHost);
      expect(padded.payloadSha256, isNot(plain.payloadSha256));
      expect(
        padded.findings.map((QrFinding item) => item.id),
        contains('url-control-character'),
      );
    });

    test('HTTP produce un hallazgo estable con evidencia', () {
      final QrInvestigation result = analyze('http://example.com');

      expect(result.severity, QrSeverity.warning);
      expect(result.findings.single.id, 'transport-http');
      expect(result.findings.single.evidence.single.value, 'http');
      expect(result.action, QrActionDecision.confirm);
    });

    test('Punycode deriva phishing como hipótesis, no como certeza', () {
      final QrInvestigation result = analyze('https://xn--pple-43d.example/login');

      expect(result.severity, QrSeverity.critical);
      expect(result.findings.map((QrFinding item) => item.id), contains('host-punycode'));
      expect(result.hypotheses, contains('qr-phishing-suspected'));
      expect(result.hypotheses, contains('credential-theft-suspected'));
    });

    test('credenciales en la autoridad quedan como ofuscación crítica', () {
      final QrInvestigation result = analyze('https://banco.example@evil.example/');

      expect(result.findings.map((QrFinding item) => item.id), contains('authority-userinfo'));
      expect(result.normalizedHost, 'evil.example');
      expect(result.action, QrActionDecision.confirm);
    });

    test('esquema ejecutable desconocido se bloquea', () {
      final QrInvestigation result = analyze('javascript:alert(1)');

      expect(result.findings.single.id, 'scheme-blocked');
      expect(result.action, QrActionDecision.block);
      expect(result.hypotheses, contains('unsafe-uri-execution'));
    });

    test('un control codificado bloquea también una acción mailto', () {
      final QrInvestigation result = analyze(
        'mailto:persona@example.com?subject=hola%0abcc:otra@example.com',
      );

      expect(
        result.findings.map((QrFinding item) => item.id),
        contains('url-control-character'),
      );
      expect(result.action, QrActionDecision.block);
    });

    test('detecta una URL anidada que cambia de host', () {
      final QrInvestigation result = analyze(
        'https://example.com/out?redirect=https%3A%2F%2Fevil.example%2Flogin',
      );

      final QrFinding finding = result.findings.firstWhere(
        (QrFinding item) => item.id == 'redirect-nested-domain',
      );
      expect(finding.evidence.map((QrEvidenceFact item) => item.value), contains('evil.example'));
    });

    test('detecta posible entrega de archivo ejecutable', () {
      final QrInvestigation result = analyze('https://download.example/update.apk');

      expect(result.findings.map((QrFinding item) => item.id), contains('download-dangerous-extension'));
      expect(result.hypotheses, contains('malware-delivery-suspected'));
    });

    test('destino privado se trata como indicio local, salvo política explícita', () {
      final QrInvestigation blocked = analyze('https://192.168.1.10/admin');
      final QrInvestigation allowedByPolicy = analyze(
        'https://192.168.1.10/admin',
        policy: const QrAnalysisPolicy(allowPrivateTargets: true),
      );

      expect(blocked.findings.map((QrFinding item) => item.id), contains('host-private-or-local'));
      expect(allowedByPolicy.findings.map((QrFinding item) => item.id), isNot(contains('host-private-or-local')));
    });

    test('un dominio que comienza en fc no se confunde con un IPv6 privado', () {
      final QrInvestigation result = analyze('https://fca.example/documento');

      expect(
        result.findings.map((QrFinding item) => item.id),
        isNot(contains('host-private-or-local')),
      );
    });

    test('instrucción de pago exige revisión sin declarar fraude', () {
      final QrInvestigation result = analyze('bitcoin:bc1qexample?amount=0.01');

      expect(result.severity, QrSeverity.warning);
      expect(result.findings.single.id, 'payment-instruction');
      expect(result.hypotheses, <String>['payment-substitution-review']);
      expect(result.action, QrActionDecision.inspectOnly);
    });

    test('política de marca detecta el token fuera del dominio autorizado', () {
      const QrAnalysisPolicy policy = QrAnalysisPolicy(
        trustedBrands: <QrTrustedBrand>[
          QrTrustedBrand(
            id: 'banco-ejemplo',
            tokens: <String>['banco-ejemplo'],
            allowedHosts: <String>['banco-ejemplo.example'],
          ),
        ],
      );

      final QrInvestigation mismatch = analyze(
        'https://banco-ejemplo.evil.example/acceso',
        policy: policy,
      );
      final QrInvestigation valid = analyze(
        'https://login.banco-ejemplo.example/acceso',
        policy: policy,
      );

      expect(mismatch.findings.map((QrFinding item) => item.id), contains('brand-domain-mismatch'));
      expect(valid.findings.map((QrFinding item) => item.id), isNot(contains('brand-domain-mismatch')));
    });
  });
}
