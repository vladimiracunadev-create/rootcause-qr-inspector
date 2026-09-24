import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rootcause_qr_inspector/models/inventory_session.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

/// Exportaciones completas de historial e inventario hacia otra aplicación.
///
/// **Estos archivos no están redactados.** JSON, CSV y XLSX contienen la carga
/// cruda, las notas y las etiquetas en claro; son lo contrario del paquete de
/// evidencia de `QrEvidenceExporter`, que omite la carga por defecto. Por eso
/// la interfaz exige una confirmación explícita antes de invocarlos.
///
/// El CSV se escribe con BOM UTF-8 y todas las celdas entrecomilladas, para que
/// una hoja de cálculo no reinterprete acentos ni separadores. La codificación
/// de CSV y XLSX se delega a `compute`, en un isolate aparte, porque un
/// historial de miles de registros bloquearía la interfaz.
abstract final class ExportService {
  static Future<void> shareHistoryHtml(List<ScanRecord> records) {
    return _shareHtml(
      buildHistoryHtml(records),
      'casos-qr-inspeccionados.html',
      'Casos QR inspeccionados',
    );
  }

  static Future<void> shareHistoryJson(List<ScanRecord> records) {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'application': 'RootCause QR Inspector',
          'schemaVersion': 2,
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'type': 'history',
          'records': records
              .map((ScanRecord item) => item.toJson())
              .toList(growable: false),
        }),
      ),
    );
    return SharePlus.instance.share(
      ShareParams(
        title: 'Casos QR inspeccionados',
        files: <XFile>[XFile.fromData(bytes, mimeType: 'application/json')],
        fileNameOverrides: const <String>['casos-qr-inspeccionados.json'],
      ),
    );
  }

  static Future<void> shareHistoryCsv(List<ScanRecord> records) {
    final List<List<String>> rows = <List<String>>[
      <String>[
        'fecha',
        'tipo',
        'formato',
        'origen',
        'riesgo',
        'favorito',
        'etiquetas',
        'contenido',
      ],
      ...records.map(
        (ScanRecord item) => <String>[
          item.scannedAt.toUtc().toIso8601String(),
          item.contentType,
          item.format,
          item.source,
          item.riskLevel.name,
          '${item.favorite}',
          item.tags.join('|'),
          item.rawValue,
        ],
      ),
    ];
    return _shareCsv(
      rows,
      'casos-qr-inspeccionados.csv',
      'Casos QR inspeccionados',
    );
  }

  static Future<void> shareHistoryXlsx(List<ScanRecord> records) {
    final List<List<String>> rows = <List<String>>[
      <String>[
        'Fecha',
        'Tipo',
        'Formato',
        'Origen',
        'Riesgo',
        'Favorito',
        'Etiquetas',
        'Notas',
        'Contenido',
      ],
      ...records.map(
        (ScanRecord item) => <String>[
          item.scannedAt.toUtc().toIso8601String(),
          item.contentType,
          item.format,
          item.source,
          item.riskLevel.name,
          item.favorite ? 'Sí' : 'No',
          item.tags.join(' | '),
          item.notes,
          item.rawValue,
        ],
      ),
    ];
    return _shareXlsx(
      rows,
      'Casos QR',
      'casos-qr-inspeccionados.xlsx',
      'Casos QR inspeccionados',
    );
  }

  static Future<void> shareInventoryCsv(InventorySession session) {
    final List<List<String>> rows = <List<String>>[
      <String>[
        'sesion',
        'codigo',
        'formato',
        'descripcion',
        'cantidad',
        'primera_lectura',
        'ultima_lectura',
        'notas',
      ],
      ...session.items.values.map(
        (InventoryItem item) => <String>[
          session.name,
          item.code,
          item.format,
          item.label,
          '${item.quantity}',
          item.firstScannedAt.toIso8601String(),
          item.lastScannedAt.toIso8601String(),
          item.notes,
        ],
      ),
    ];
    return _shareCsv(
      rows,
      'inventario-${session.id}.csv',
      'Inventario ${session.name}',
    );
  }

  static Future<void> shareInventoryJson(InventorySession session) {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'application': 'RootCause QR Inspector',
          'schemaVersion': 2,
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'type': 'inventory',
          'session': session.toJson(),
        }),
      ),
    );
    return SharePlus.instance.share(
      ShareParams(
        title: 'Inventario ${session.name}',
        files: <XFile>[XFile.fromData(bytes, mimeType: 'application/json')],
        fileNameOverrides: <String>['inventario-${session.id}.json'],
      ),
    );
  }

  static Future<void> shareInventoryXlsx(InventorySession session) {
    final List<List<String>> rows = <List<String>>[
      <String>[
        'Sesión',
        'Código',
        'Formato',
        'Descripción',
        'Cantidad',
        'Primera lectura',
        'Última lectura',
        'Notas',
      ],
      ...session.items.values.map(
        (InventoryItem item) => <String>[
          session.name,
          item.code,
          item.format,
          item.label,
          '${item.quantity}',
          item.firstScannedAt.toIso8601String(),
          item.lastScannedAt.toIso8601String(),
          item.notes,
        ],
      ),
    ];
    return _shareXlsx(
      rows,
      'Inventario',
      'inventario-${session.id}.xlsx',
      'Inventario ${session.name}',
    );
  }

  static Future<void> shareInventoryHtml(InventorySession session) {
    return _shareHtml(
      buildInventoryHtml(session),
      'inventario-${session.id}.html',
      'Inventario ${session.name}',
    );
  }

  @visibleForTesting
  static String buildHistoryHtml(List<ScanRecord> records) {
    final String rows = records.map((ScanRecord item) {
      return _htmlRow(<String>[
        item.scannedAt.toUtc().toIso8601String(),
        item.contentType,
        item.format,
        item.source,
        item.riskLevel.name,
        item.favorite ? 'Sí' : 'No',
        item.tags.join(' | '),
        item.notes,
        _linkOrText(item.rawValue),
      ], lastCellIsMarkup: true);
    }).join();
    return _htmlDocument(
      title: 'Casos QR inspeccionados',
      notice:
          'Exportación local sin cifrar. Los enlaces web se abren en una pestaña nueva.',
      headers: const <String>[
        'Fecha UTC',
        'Tipo',
        'Formato',
        'Origen',
        'Riesgo',
        'Favorito',
        'Etiquetas',
        'Notas',
        'Contenido',
      ],
      rows: rows,
    );
  }

  @visibleForTesting
  static String buildInventoryHtml(InventorySession session) {
    final String rows = session.items.values.map((InventoryItem item) {
      return _htmlRow(
        <String>[
          session.name,
          _linkOrText(item.code),
          item.format,
          item.label,
          '${item.quantity}',
          item.firstScannedAt.toUtc().toIso8601String(),
          item.lastScannedAt.toUtc().toIso8601String(),
          item.notes,
        ],
        markupCells: const <int>{1},
      );
    }).join();
    return _htmlDocument(
      title: 'Inventario ${session.name}',
      notice:
          'Exportación local sin cifrar. Los enlaces web se abren en una pestaña nueva.',
      headers: const <String>[
        'Sesión',
        'Código',
        'Formato',
        'Descripción',
        'Cantidad',
        'Primera lectura',
        'Última lectura',
        'Notas',
      ],
      rows: rows,
    );
  }

  static Future<void> _shareCsv(
    List<List<String>> rows,
    String name,
    String title,
  ) async {
    final Uint8List bytes = Uint8List.fromList(
      await compute<List<List<String>>, List<int>>(_encodeCsv, rows),
    );
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        files: <XFile>[XFile.fromData(bytes, mimeType: 'text/csv')],
        fileNameOverrides: <String>[name],
      ),
    );
  }

  static Future<void> _shareXlsx(
    List<List<String>> rows,
    String sheetName,
    String name,
    String title,
  ) async {
    final List<int>? encoded = await compute<Map<String, Object?>, List<int>?>(
      _encodeXlsx,
      <String, Object?>{'rows': rows, 'sheetName': sheetName},
    );
    if (encoded == null) return;
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        files: <XFile>[
          XFile.fromData(
            Uint8List.fromList(encoded),
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: <String>[name],
      ),
    );
  }

  static Future<void> _shareHtml(String html, String name, String title) {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(html));
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        files: <XFile>[
          XFile.fromData(bytes, mimeType: 'text/html; charset=utf-8'),
        ],
        fileNameOverrides: <String>[name],
      ),
    );
  }
}

String _htmlDocument({
  required String title,
  required String notice,
  required List<String> headers,
  required String rows,
}) {
  final String safeTitle = _escapeText(title);
  final String headings = headers
      .map((String value) => '<th>${_escapeText(value)}</th>')
      .join();
  return '''<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>$safeTitle</title>
  <style>
    body{font-family:system-ui,sans-serif;margin:2rem;color:#112b27;background:#f7fbfa}
    h1{margin-bottom:.25rem}p{color:#445b57}table{border-collapse:collapse;width:100%;background:white}
    th,td{border:1px solid #c8d8d4;padding:.55rem;text-align:left;vertical-align:top;word-break:break-word}
    th{background:#daf3ed}tbody tr:nth-child(even){background:#f2f8f6}a{color:#087a6d}
  </style>
</head>
<body>
  <h1>$safeTitle</h1>
  <p>${_escapeText(notice)}</p>
  <table><thead><tr>$headings</tr></thead><tbody>$rows</tbody></table>
</body>
</html>
''';
}

String _htmlRow(
  List<String> cells, {
  bool lastCellIsMarkup = false,
  Set<int> markupCells = const <int>{},
}) {
  final int last = cells.length - 1;
  return '<tr>${List<String>.generate(cells.length, (int index) {
    final bool markup = markupCells.contains(index) || (lastCellIsMarkup && index == last);
    return '<td>${markup ? cells[index] : _escapeText(cells[index])}</td>';
  }).join()}</tr>';
}

String _linkOrText(String value) {
  final Uri? uri = Uri.tryParse(value);
  if (uri != null &&
      <String>{'http', 'https'}.contains(uri.scheme) &&
      uri.host.isNotEmpty) {
    final String safe = const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(value);
    return '<a href="$safe" target="_blank" rel="noopener noreferrer">${_escapeText(value)}</a>';
  }
  return _escapeText(value);
}

String _escapeText(String value) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(value);

List<int> _encodeCsv(List<List<String>> rows) {
  String csvCell(String value) => '"${value.replaceAll('"', '""')}"';
  final String csv = rows
      .map((List<String> row) => row.map(csvCell).join(','))
      .join('\r\n');
  return <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
}

List<int>? _encodeXlsx(Map<String, Object?> request) {
  final List<List<String>> rows = (request['rows'] as List<dynamic>)
      .map<List<String>>(
        (dynamic row) => (row as List<dynamic>)
            .map((dynamic value) => '$value')
            .toList(growable: false),
      )
      .toList(growable: false);
  final String sheetName = request['sheetName'] as String;
  final Excel workbook = Excel.createExcel();
  final String firstSheet = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  for (final List<String> row in rows) {
    sheet.appendRow(
      row
          .map<TextCellValue>((String value) => TextCellValue(value))
          .toList(growable: false),
    );
  }
  if (firstSheet != sheetName) workbook.delete(firstSheet);
  return workbook.save();
}
