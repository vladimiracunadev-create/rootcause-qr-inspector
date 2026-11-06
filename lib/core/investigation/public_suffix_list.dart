import 'package:rootcause_qr_inspector/core/investigation/public_suffix_data.dart';

/// Reglas de sufijo público aplicadas al algoritmo de la Public Suffix List.
///
/// Responde a la única pregunta que decide si dos hosts son el mismo dueño:
/// **cuál es el dominio registrable**. Sin esta lista, comparar por sufijo es
/// adivinar: `banco.cl` y `otro.cl` comparten `.cl` sin tener nada que ver, y
/// `pagos.cl.atacante.example` no pertenece a `.cl` aunque lo lleve escrito.
///
/// Implementa el algoritmo publicado: gana la regla coincidente más larga, las
/// reglas comodín (`*.ck`) consumen una etiqueta cualquiera, las excepciones
/// (`!www.ck`) acortan el sufijo, y un host sin ninguna regla cae en la regla
/// implícita `*`, es decir, su última etiqueta.
///
/// Lo que esta clase **no** hace: resolver DNS, comprobar que el dominio
/// exista ni decidir si es legítimo. Solo delimita quién podría registrarlo.
///
/// Las reglas vienen de `public_suffix_data.dart`, generado desde el archivo
/// original de Mozilla con `tool/generate_identity_data.py`. Esa copia tiene
/// fecha: un sufijo creado después no se reconoce y el host cae entonces en la
/// regla implícita, que es el comportamiento conservador.
class PublicSuffixList {
  const PublicSuffixList._(this._icann, this._all);

  /// Lista incluida en la aplicación, con las dos secciones del archivo.
  ///
  /// Se construye una vez y se reutiliza: son más de diez mil reglas y
  /// rehacerlas en cada análisis sería gasto puro.
  static final PublicSuffixList bundled = PublicSuffixList.parse(
    icann: kIcannPublicSuffixRules,
    private: kPrivatePublicSuffixRules,
  );

  /// Construye la lista desde el texto de las dos secciones.
  ///
  /// Se expone para que una organización pueda analizar con su propia copia
  /// —más reciente, o recortada— sin tocar el motor.
  factory PublicSuffixList.parse({
    required String icann,
    required String private,
  }) {
    final _SuffixRules icannRules = _SuffixRules.parse(<String>[icann]);
    final _SuffixRules allRules = _SuffixRules.parse(<String>[icann, private]);
    return PublicSuffixList._(icannRules, allRules);
  }

  final _SuffixRules _icann;
  final _SuffixRules _all;

  int get icannRuleCount => _icann.length;

  int get ruleCount => _all.length;

  /// Sufijo público del host, o null si el host no sirve para preguntarlo.
  ///
  /// [icannOnly] deja fuera la sección privada. Importa según la pregunta: para
  /// saber si `github.io` delega subdominios a terceros hace falta la sección
  /// privada; para saber si una etiqueta imita un dominio de primer nivel, no.
  String? publicSuffixOf(String host, {bool icannOnly = false}) {
    final List<String>? labels = _labelsOf(host);
    if (labels == null) return null;
    final _SuffixRules rules = icannOnly ? _icann : _all;

    // Las excepciones mandan sobre cualquier otra regla, por eso van primero y
    // en su propio recorrido.
    for (int index = 0; index < labels.length; index++) {
      if (rules.exceptions.contains(labels.sublist(index).join('.'))) {
        return labels.sublist(index + 1).join('.');
      }
    }
    // El recorrido empieza por el candidato más largo, así que la primera
    // coincidencia ya es la regla que prevalece.
    for (int index = 0; index < labels.length; index++) {
      final String candidate = labels.sublist(index).join('.');
      if (rules.exact.contains(candidate)) return candidate;
      if (index + 1 < labels.length &&
          rules.wildcardParents.contains(labels.sublist(index + 1).join('.'))) {
        return candidate;
      }
    }
    // Regla implícita `*`: la última etiqueta.
    return labels.last;
  }

  /// Dominio registrable del host: el sufijo público más una etiqueta.
  ///
  /// Null cuando el host **es** un sufijo público —`com`, `co.uk`— porque
  /// entonces no hay dominio que nadie haya registrado, y cuando el host es una
  /// dirección IP o está vacío.
  String? registrableDomainOf(String host, {bool icannOnly = false}) {
    final List<String>? labels = _labelsOf(host);
    if (labels == null) return null;
    final String? suffix = publicSuffixOf(host, icannOnly: icannOnly);
    if (suffix == null) return null;
    final int suffixLabels = suffix.split('.').length;
    if (labels.length <= suffixLabels) return null;
    return labels.sublist(labels.length - suffixLabels - 1).join('.');
  }

  /// Si el candidato es exactamente un sufijo público conocido.
  ///
  /// Es la pregunta inversa a la del dominio registrable: ¿esta etiqueta —o
  /// este par de etiquetas— es un dominio de primer nivel escrito dentro del
  /// host para que parezca el destino?
  bool isPublicSuffix(String candidate, {bool icannOnly = true}) {
    final String value = candidate.trim().toLowerCase();
    if (value.isEmpty) return false;
    final _SuffixRules rules = icannOnly ? _icann : _all;
    if (rules.exact.contains(value)) return true;
    final List<String> labels = value.split('.');
    if (labels.length < 2) return false;
    return rules.wildcardParents.contains(labels.sublist(1).join('.'));
  }

  /// Si los dos hosts comparten dominio registrable.
  ///
  /// Reemplaza la comparación por sufijo textual, que daba por familia a
  /// cualquier par de hosts donde uno terminara en el otro.
  bool sameRegistrableDomain(String first, String second) {
    final String? left = registrableDomainOf(first);
    final String? right = registrableDomainOf(second);
    if (left == null || right == null) {
      return first.toLowerCase() == second.toLowerCase();
    }
    return left == right;
  }

  /// Etiquetas utilizables del host, o null si no hay nada que analizar.
  ///
  /// Una IP no tiene dominio registrable, y preguntarlo devolvería `1.1` como
  /// si lo fuera: el motor ya la trata con `host-ip-literal`.
  static List<String>? _labelsOf(String host) {
    final String value = host.trim().toLowerCase().replaceAll(
      RegExp(r'\.$'),
      '',
    );
    if (value.isEmpty || value.contains(':')) return null;
    final List<String> labels = value.split('.');
    if (labels.any((String label) => label.isEmpty)) return null;
    if (labels.every((String label) => int.tryParse(label) != null)) {
      return null;
    }
    return labels;
  }
}

/// Las tres formas que tiene una regla de la lista.
class _SuffixRules {
  const _SuffixRules(this.exact, this.wildcardParents, this.exceptions);

  factory _SuffixRules.parse(List<String> sources) {
    final Set<String> exact = <String>{};
    final Set<String> wildcardParents = <String>{};
    final Set<String> exceptions = <String>{};
    for (final String source in sources) {
      for (final String raw in source.split('\n')) {
        final String rule = raw.trim().toLowerCase();
        if (rule.isEmpty || rule.startsWith('//')) continue;
        if (rule.startsWith('!')) {
          exceptions.add(rule.substring(1));
        } else if (rule.startsWith('*.')) {
          wildcardParents.add(rule.substring(2));
        } else {
          exact.add(rule);
        }
      }
    }
    return _SuffixRules(exact, wildcardParents, exceptions);
  }

  final Set<String> exact;
  final Set<String> wildcardParents;
  final Set<String> exceptions;

  int get length => exact.length + wildcardParents.length + exceptions.length;
}
