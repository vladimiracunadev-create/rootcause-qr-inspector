import 'package:rootcause_qr_inspector/features/formats/domain/content_parser.dart';
import 'package:rootcause_qr_inspector/models/parsed_content.dart';
import 'package:rootcause_qr_inspector/services/content_interpreter.dart';

/// Registro ordenado de parsers, con el intérprete integrado como respaldo.
///
/// `register` sustituye cualquier parser con el mismo id y reordena por
/// prioridad descendente. `unregister` protege explícitamente a `builtin-v2`:
/// una extensión no puede dejar la aplicación sin intérprete.
///
/// Es un singleton (`instance`) porque `ScanRecord` lo consulta desde sus
/// constructores, donde no hay contexto de inyección disponible.
class ContentParserRegistry {
  ContentParserRegistry._() : _parsers = <ContentParser>[const LegacyContentParser()];
  static final ContentParserRegistry instance = ContentParserRegistry._();

  final List<ContentParser> _parsers;
  List<ContentParser> get parsers => List<ContentParser>.unmodifiable(_parsers);

  void register(ContentParser parser) {
    _parsers.removeWhere((ContentParser item) => item.id == parser.id);
    _parsers.add(parser);
    _parsers.sort((ContentParser a, ContentParser b) => b.priority.compareTo(a.priority));
  }

  void unregister(String id) => _parsers.removeWhere((ContentParser item) => item.id == id && id != 'builtin-v2');

  ParsedContent parse(String rawValue) {
    for (final ContentParser parser in _parsers) {
      if (parser.canParse(rawValue)) return parser.parse(rawValue);
    }
    return ContentInterpreter.parse(rawValue);
  }
}

/// Parser integrado: acepta cualquier carga y delega en [ContentInterpreter].
///
/// Su prioridad negativa garantiza que siempre sea el último candidato.
class LegacyContentParser implements ContentParser {
  const LegacyContentParser();
  @override
  String get id => 'builtin-v2';
  @override
  int get priority => -1000;
  @override
  bool canParse(String rawValue) => true;
  @override
  ParsedContent parse(String rawValue) => ContentInterpreter.parse(rawValue);
}
