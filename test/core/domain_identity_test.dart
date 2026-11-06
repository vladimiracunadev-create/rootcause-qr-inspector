import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/core/investigation/public_suffix_list.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_analysis_policy.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation.dart';
import 'package:rootcause_qr_inspector/core/investigation/qr_investigation_engine.dart';
import 'package:rootcause_qr_inspector/core/investigation/unicode_skeleton.dart';
import 'package:rootcause_qr_inspector/services/content_interpreter.dart';

/// Identidad del dominio: sufijo público, esqueleto UTS #39 y las dos reglas
/// que ambos habilitan.
void main() {
  QrInvestigation analyze(
    String value, {
    QrAnalysisPolicy policy = const QrAnalysisPolicy(),
  }) => QrInvestigationEngine.analyze(
    value,
    parsed: ContentInterpreter.parse(value),
    policy: policy,
    analyzedAt: DateTime.utc(2026, 11, 6),
  );

  List<String> idsOf(QrInvestigation result) =>
      result.findings.map((QrFinding item) => item.id).toList(growable: false);

  String? factOf(QrInvestigation result, String ruleId, String factId) {
    for (final QrFinding finding in result.findings) {
      if (finding.id != ruleId) continue;
      for (final QrEvidenceFact fact in finding.evidence) {
        if (fact.id == factId) return fact.value;
      }
    }
    return null;
  }

  // `раураӏ.example` está escrito entero en cirílico: cada carácter tiene su
  // equivalente ASCII declarado por Unicode, así que se lee como una marca
  // latina sin mezclar nada.
  const String cyrillicSpoof = 'https://раураӏ.example/pagar';

  group('PublicSuffixList', () {
    final PublicSuffixList list = PublicSuffixList.bundled;

    test('la lista incluida trae las dos secciones del archivo', () {
      expect(list.icannRuleCount, greaterThan(5000));
      expect(list.ruleCount, greaterThan(list.icannRuleCount));
    });

    test(
      'el dominio registrable usa la regla más larga, no la última etiqueta',
      () {
        expect(list.registrableDomainOf('www.ejemplo.co.uk'), 'ejemplo.co.uk');
        expect(list.registrableDomainOf('tienda.com.br'), 'tienda.com.br');
        expect(list.registrableDomainOf('a.b.c.ejemplo.com'), 'ejemplo.com');
        expect(list.publicSuffixOf('www.ejemplo.co.uk'), 'co.uk');
      },
    );

    test('la sección privada separa a dos inquilinos del mismo dominio', () {
      // Con la sección privada, `github.io` es el sufijo y cada usuario tiene
      // su propio dominio registrable; sin ella el sufijo es `io` y los dos
      // usuarios parecerían el mismo dueño.
      expect(list.registrableDomainOf('user.github.io'), 'user.github.io');
      expect(
        list.registrableDomainOf('user.github.io', icannOnly: true),
        'github.io',
      );
      expect(list.sameRegistrableDomain('a.github.io', 'b.github.io'), isFalse);
    });

    test(
      'las reglas comodín y sus excepciones se aplican como manda la lista',
      () {
        // `*.ck` es comodín y `!www.ck` su excepción.
        expect(list.publicSuffixOf('foo.bar.ck'), 'bar.ck');
        expect(list.publicSuffixOf('www.ck'), 'ck');
        expect(list.registrableDomainOf('www.ck'), 'www.ck');
      },
    );

    test('un sufijo público no tiene dominio registrable', () {
      expect(list.registrableDomainOf('co.uk'), isNull);
      expect(list.registrableDomainOf('com'), isNull);
    });

    test('una IP o un host vacío no se convierten en dominio', () {
      expect(list.registrableDomainOf('192.168.1.10'), isNull);
      expect(list.registrableDomainOf('::1'), isNull);
      expect(list.registrableDomainOf(''), isNull);
      expect(list.registrableDomainOf('   '), isNull);
    });

    test(
      'la misma familia es el mismo dominio registrable, no el mismo texto',
      () {
        expect(
          list.sameRegistrableDomain('pagos.ejemplo.com', 'www.ejemplo.com'),
          isTrue,
        );
        // El sufijo textual daba por familia a estos dos: uno termina en el otro.
        expect(
          list.sameRegistrableDomain(
            'ejemplo.com',
            'ejemplo.com.atacante.example',
          ),
          isFalse,
        );
        expect(
          list.sameRegistrableDomain('ejemplo.co.uk', 'otro.co.uk'),
          isFalse,
        );
      },
    );

    test('una organización puede analizar con su propia copia de la lista', () {
      final PublicSuffixList own = PublicSuffixList.parse(
        icann: 'example\ninterno.example',
        private: '',
      );

      expect(
        own.registrableDomainOf('app.interno.example'),
        'app.interno.example',
      );
      expect(own.isPublicSuffix('interno.example'), isTrue);
      expect(own.isPublicSuffix('com'), isFalse);
    });

    test(
      'el sufijo reconocido no depende del punto final ni de mayúsculas',
      () {
        expect(list.registrableDomainOf('WWW.Ejemplo.COM.'), 'ejemplo.com');
      },
    );
  });

  group('UnicodeSkeleton', () {
    test('el esqueleto lleva otra escritura a su lectura latina', () {
      expect(UnicodeSkeleton.of('раураӏ'), 'paypal');
      // Formas de ancho completo: otra via clásica de imitación.
      expect(UnicodeSkeleton.of('ｐａｙ'), 'pay');
    });

    test('un host en otra escritura que se lee en latín es confuso', () {
      expect(UnicodeSkeleton.isWholeScriptConfusable('раураӏ.example'), isTrue);
    });

    test('el latín con diacríticos no es confuso', () {
      // `café` y `piñón` son escritura legítima del idioma. Tratarlas como
      // engaño volvería sospechosa a media internet hispanohablante.
      expect(UnicodeSkeleton.isWholeScriptConfusable('café.example'), isFalse);
      expect(UnicodeSkeleton.isWholeScriptConfusable('piñón.example'), isFalse);
    });

    test(
      'un host ASCII nunca es confuso, y un host no latino real tampoco',
      () {
        expect(UnicodeSkeleton.isWholeScriptConfusable('ejemplo.com'), isFalse);
        expect(UnicodeSkeleton.isWholeScriptConfusable(''), isFalse);
        // Un dominio internacional de verdad: su esqueleto no es ASCII, así que
        // no imita ninguna palabra latina.
        expect(UnicodeSkeleton.isWholeScriptConfusable('例え.example'), isFalse);
      },
    );

    test(
      'la forma comparable iguala la marca con su copia en otra escritura',
      () {
        expect(
          UnicodeSkeleton.comparable('bаnco-ejemplo'),
          UnicodeSkeleton.comparable('BancoEjemplo'),
        );
      },
    );
  });

  group('reglas de identidad del motor', () {
    test('un host Unicode se analiza decodificado, no en porcentajes', () {
      // Regresión de 0.1.4: `Uri` entrega el host percent-codificado, así que
      // `host-unicode` y `host-mixed-script` no se disparaban nunca con un
      // host escrito en otro alfabeto, y la evidencia mostraba porcentajes.
      final QrInvestigation result = analyze(cyrillicSpoof);

      expect(result.normalizedHost, isNotNull);
      expect(result.normalizedHost, isNot(contains('%')));
      expect(idsOf(result), contains('host-unicode'));
      expect(idsOf(result), contains('host-mixed-script'));
    });

    test('el host escrito entero en otra escritura es hallazgo crítico', () {
      final QrInvestigation result = analyze(cyrillicSpoof);

      expect(idsOf(result), contains('host-whole-script-confusable'));
      expect(result.severity, QrSeverity.critical);
      expect(result.action, QrActionDecision.confirm);
      // La evidencia incluye la lectura latina: es lo que la persona cree estar
      // viendo, y verlo escrito al lado es lo que permite decidir.
      expect(
        factOf(result, 'host-whole-script-confusable', 'skeleton'),
        'paypal.example',
      );
      expect(result.hypotheses, contains('qr-phishing-suspected'));
    });

    test('un dominio internacional legítimo no dispara la suplantación', () {
      final QrInvestigation result = analyze('https://café.example/menu');

      expect(idsOf(result), contains('host-unicode'));
      expect(idsOf(result), isNot(contains('host-whole-script-confusable')));
      expect(result.severity, QrSeverity.warning);
    });

    test('un dominio conocido escrito como subdominio ajeno se declara', () {
      final QrInvestigation result = analyze(
        'https://pagos.com.cuenta.example/pagar',
      );

      expect(idsOf(result), contains('host-embedded-suffix'));
      expect(factOf(result, 'host-embedded-suffix', 'embeddedSuffix'), 'com');
      // El dato que contesta la pregunta: el dominio que alguien registró.
      expect(
        factOf(result, 'host-embedded-suffix', 'registrableDomain'),
        'cuenta.example',
      );
      expect(result.hypotheses, contains('qr-phishing-suspected'));
    });

    test('un subdominio de idioma o de región no es un sufijo incrustado', () {
      // Límite declarado: los ccTLD de dos letras no disparan la regla porque
      // `es.`, `de.` y `cl.` son subdominios normales.
      for (final String payload in <String>[
        'https://es.example.com/precios',
        'https://www.cl.example.com/precios',
        'https://user.github.io/pagina',
        'https://www.ejemplo.co.uk/ofertas',
      ]) {
        expect(
          idsOf(analyze(payload)),
          isNot(contains('host-embedded-suffix')),
          reason: payload,
        );
      }
    });

    test('la redirección anidada compara dominios registrables', () {
      final QrInvestigation foreign = analyze(
        'https://ejemplo.com/ir?url=https://ejemplo.com.atacante.example/acceso',
      );
      final QrInvestigation own = analyze(
        'https://pagos.ejemplo.com/ir?url=https://www.ejemplo.com/factura',
      );

      // El sufijo textual daba por familia al destino del primer caso.
      expect(idsOf(foreign), contains('redirect-nested-domain'));
      expect(idsOf(own), isNot(contains('redirect-nested-domain')));
    });

    test('una marca escrita en otra escritura ya no esquiva su token', () {
      const QrAnalysisPolicy policy = QrAnalysisPolicy(
        trustedBrands: <QrTrustedBrand>[
          QrTrustedBrand(
            id: 'banco-demo',
            tokens: <String>['bancoejemplo'],
            allowedHosts: <String>['banco.example'],
          ),
        ],
      );

      final QrInvestigation spoofed = analyze(
        'https://bаncoejemplo.example/acceso',
        policy: policy,
      );
      final QrInvestigation legitimate = analyze(
        'https://banco.example/acceso',
        policy: policy,
      );

      expect(idsOf(spoofed), contains('brand-domain-mismatch'));
      expect(idsOf(legitimate), isNot(contains('brand-domain-mismatch')));
    });

    test('el dominio registrable acompaña al exceso de subdominios', () {
      final QrInvestigation result = analyze(
        'https://a.b.c.d.e.f.ejemplo.com/pagina',
      );

      expect(idsOf(result), contains('host-deep-subdomains'));
      expect(
        factOf(result, 'host-deep-subdomains', 'registrableDomain'),
        'ejemplo.com',
      );
    });

    test('las dos reglas nuevas se evalúan siempre que haya URL web', () {
      final QrInvestigation result = analyze('https://ejemplo.com/pagina');

      expect(
        result.evaluatedRuleIds,
        containsAll(<String>[
          'host-whole-script-confusable',
          'host-embedded-suffix',
        ]),
      );
      expect(result.findings, isEmpty);
    });

    test('el motor declara la versión que corresponde a 28 reglas', () {
      // Añadir una regla sin subir la versión dejaría dos evidencias
      // incomparables declarándose comparables.
      expect(QrInvestigationEngine.engineVersion, '0.2.0');
    });
  });
}
