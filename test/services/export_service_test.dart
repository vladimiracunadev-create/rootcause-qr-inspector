import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/models/inventory_session.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';
import 'package:rootcause_qr_inspector/services/export_service.dart';

void main() {
  test('HTML del historial es navegable y neutraliza contenido activo', () {
    final List<ScanRecord> records = <ScanRecord>[
      ScanRecord.manual(
        rawValue: 'https://example.com/report?a=1&b=2',
        format: 'QR Code',
        source: 'Prueba',
      ),
      ScanRecord.manual(
        rawValue: '<script>alert("x")</script>',
        format: 'Code 128',
        source: 'Prueba',
      ),
    ];

    final String html = ExportService.buildHistoryHtml(records);

    expect(html, startsWith('<!doctype html>'));
    expect(html, contains('<meta charset="utf-8">'));
    expect(html, contains('target="_blank"'));
    expect(html, contains('rel="noopener noreferrer"'));
    expect(html, contains('a=1&amp;b=2'));
    expect(html, isNot(contains('<script>alert')));
    expect(html, contains('&lt;script&gt;alert'));
  });

  test('HTML del inventario abre enlaces en otra pestaña y escapa notas', () {
    final DateTime observedAt = DateTime.utc(2026, 9, 24, 12);
    final InventorySession session = InventorySession(
      id: 'synthetic',
      name: 'Biblioteca <central>',
      createdAt: observedAt,
      items: <String, InventoryItem>{
        'https://example.com/book?a=1&b=2': InventoryItem(
          code: 'https://example.com/book?a=1&b=2',
          format: 'QR Code',
          label: 'Libro',
          quantity: 2,
          firstScannedAt: observedAt,
          lastScannedAt: observedAt,
          notes: '<img src=x onerror=alert(1)>',
        ),
      },
    );

    final String html = ExportService.buildInventoryHtml(session);

    expect(html, startsWith('<!doctype html>'));
    expect(html, contains('Biblioteca &lt;central&gt;'));
    expect(html, contains('target="_blank"'));
    expect(html, contains('rel="noopener noreferrer"'));
    expect(html, contains('book?a=1&amp;b=2'));
    expect(html, isNot(contains('<img src=x')));
    expect(html, contains('&lt;img src=x onerror=alert(1)&gt;'));
  });
}
