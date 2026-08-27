import 'package:rootcause_qr_inspector/models/parsed_content.dart';

/// Frontera de extensión para interpretar formatos adicionales.
///
/// Un parser declara un [id] estable, una [priority] —mayor gana— y responde
/// si sabe interpretar una carga. El parser integrado usa prioridad -1000, de
/// modo que cualquier extensión registrada se evalúa antes que él.
abstract interface class ContentParser {
  String get id;
  int get priority;
  bool canParse(String rawValue);
  ParsedContent parse(String rawValue);
}
