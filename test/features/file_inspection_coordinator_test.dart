import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/core/performance/cancellation_token.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/file_code_decoder.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/file_inspection_coordinator.dart';

class _FakeDecoder implements FileCodeDecoder {
  _FakeDecoder(this.results, {this.beforeReturn});

  final Map<String, List<Barcode>> results;
  final void Function(String path)? beforeReturn;

  @override
  Future<List<Barcode>> decode(String imagePath) async {
    beforeReturn?.call(imagePath);
    return results[imagePath] ?? const <Barcode>[];
  }
}

class _SlowDecoder implements FileCodeDecoder {
  @override
  Future<List<Barcode>> decode(String imagePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return <Barcode>[_barcode('https://slow.example')];
  }
}

Barcode _barcode(String value) =>
    Barcode(format: BarcodeFormat.qrCode, rawValue: value, displayValue: value);

void main() {
  test('valida extensiones de imagen sin depender de rutas privadas', () {
    expect(
      FileInspectionInputValidator.isSupportedImageName('CAPTURE.PNG'),
      isTrue,
    );
    expect(
      FileInspectionInputValidator.isSupportedImageName('photo.heic'),
      isTrue,
    );
    expect(
      FileInspectionInputValidator.isSupportedImageName('archivo'),
      isFalse,
    );
    expect(
      FileInspectionInputValidator.isSupportedImageName('document.pdf'),
      isFalse,
    );
    expect(FileInspectionInputValidator.isAllowedFileSize(0), isFalse);
    expect(
      FileInspectionInputValidator.isAllowedFileSize(
        FileInspectionLimits.maxFileBytes,
      ),
      isTrue,
    );
    expect(
      FileInspectionInputValidator.isAllowedFileSize(
        FileInspectionLimits.maxFileBytes + 1,
      ),
      isFalse,
    );
    expect(FileInspectionInputValidator.pdfPagesToInspect(120), 50);
    expect(FileInspectionInputValidator.pdfPagesToInspect(18), 18);
  });

  test(
    'procesa todos los códigos y deduplica solo dentro de cada origen',
    () async {
      final FileInspectionCoordinator coordinator = FileInspectionCoordinator(
        decoder: _FakeDecoder(<String, List<Barcode>>{
          'one.png': <Barcode>[
            _barcode('https://normal.example'),
            _barcode('https://normal.example'),
            _barcode('mailto:person@example.com'),
          ],
          'two.png': <Barcode>[
            _barcode('https://normal.example'),
            _barcode('WIFI:T:WPA;S:Lab;P:synthetic;;'),
          ],
        }),
      );

      final FileInspectionResult result = await coordinator
          .inspect(const <FileInspectionUnit>[
            FileInspectionUnit(imagePath: 'one.png', source: 'Imagen · 1'),
            FileInspectionUnit(imagePath: 'two.png', source: 'Imagen · 2'),
          ]);

      expect(result.records, hasLength(4));
      expect(result.unitsInspected, 2);
      expect(result.unitsWithoutCodes, 0);
      expect(
        result.records.where(
          (record) => record.rawValue == 'https://normal.example',
        ),
        hasLength(2),
      );
      expect(result.records.first.source, 'Imagen · 1');
      expect(result.records.last.source, 'Imagen · 2');
      expect(result.records.last.isSensitive, isTrue);
    },
  );

  test('informa unidades sin códigos legibles', () async {
    final FileInspectionCoordinator coordinator = FileInspectionCoordinator(
      decoder: _FakeDecoder(<String, List<Barcode>>{
        'empty.png': const <Barcode>[],
        'blank.png': <Barcode>[Barcode(format: BarcodeFormat.qrCode)],
      }),
    );

    final FileInspectionResult result = await coordinator
        .inspect(const <FileInspectionUnit>[
          FileInspectionUnit(imagePath: 'empty.png', source: 'PDF · página 1'),
          FileInspectionUnit(imagePath: 'blank.png', source: 'PDF · página 2'),
        ]);

    expect(result.records, isEmpty);
    expect(result.unitsWithoutCodes, 2);
  });

  test('la cancelación descarta el resultado parcial', () async {
    final CancellationToken token = CancellationToken();
    final FileInspectionCoordinator coordinator = FileInspectionCoordinator(
      decoder: _FakeDecoder(
        <String, List<Barcode>>{
          'one.png': <Barcode>[_barcode('https://one.example')],
          'two.png': <Barcode>[_barcode('https://two.example')],
        },
        beforeReturn: (String path) {
          if (path == 'two.png') token.cancel();
        },
      ),
    );

    await expectLater(
      coordinator.inspect(const <FileInspectionUnit>[
        FileInspectionUnit(imagePath: 'one.png', source: 'PDF · página 1'),
        FileInspectionUnit(imagePath: 'two.png', source: 'PDF · página 2'),
      ], cancellationToken: token),
      throwsA(isA<OperationCancelledException>()),
    );
  });

  test('un decodificador bloqueado termina por timeout', () async {
    final FileInspectionCoordinator coordinator = FileInspectionCoordinator(
      decoder: _SlowDecoder(),
      decodeTimeout: const Duration(milliseconds: 1),
    );

    await expectLater(
      coordinator.inspect(const <FileInspectionUnit>[
        FileInspectionUnit(imagePath: 'slow.png', source: 'Imagen · 1'),
      ]),
      throwsA(isA<TimeoutException>()),
    );
  });
}
