import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rootcause_qr_inspector/core/performance/cancellation_token.dart';
import 'package:rootcause_qr_inspector/features/scanner/domain/file_code_decoder.dart';
import 'package:rootcause_qr_inspector/models/scan_record.dart';

/// Resource limits shared by the file-inspection UI and services.
abstract final class FileInspectionLimits {
  static const int maxImages = 20;
  static const int maxPdfPages = 50;
  static const int maxFileBytes = 50 * 1024 * 1024;
  static const int maxImageDimension = 4096;
  // A full A4/Letter page at 2400 px makes a 30 mm-wide barcode only about
  // 240 px wide. That is marginal for dense 1D symbols once antialiasing and
  // PDF scaling are involved. Keep the raster bounded, but give the native
  // decoder a 4K source so narrow bars retain several pixels of separation.
  static const int maxPdfRasterDimension = 4096;
  static const double minPdfRasterScale = 2.0;
  static const double maxPdfRasterScale = 6.0;
  static const Duration decodeTimeout = Duration(seconds: 30);
}

abstract final class FileInspectionInputValidator {
  static const Set<String> _imageExtensions = <String>{
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
  };

  static bool isSupportedImageName(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return false;
    return _imageExtensions.contains(name.substring(dot + 1).toLowerCase());
  }

  static bool isAllowedFileSize(int byteLength) =>
      byteLength > 0 && byteLength <= FileInspectionLimits.maxFileBytes;

  static int pdfPagesToInspect(
    int totalPages, {
    int maxPages = FileInspectionLimits.maxPdfPages,
  }) {
    if (totalPages <= 0 || maxPages <= 0) return 0;
    return totalPages < maxPages ? totalPages : maxPages;
  }

  /// Scale used to rasterize a complete PDF page before native detection.
  ///
  /// PDF dimensions are expressed at 72 dpi. The bounded adaptive scale keeps
  /// ordinary A4/Letter pages close to 350 dpi while preventing unusual page
  /// sizes from creating unbounded bitmaps.
  static double pdfRasterScale(double width, double height) {
    final double longest = width > height ? width : height;
    if (longest <= 0) return FileInspectionLimits.minPdfRasterScale;
    return (FileInspectionLimits.maxPdfRasterDimension / longest)
        .clamp(
          FileInspectionLimits.minPdfRasterScale,
          FileInspectionLimits.maxPdfRasterScale,
        )
        .toDouble();
  }
}

enum FileInspectionStage { preparing, decoding }

class FileInspectionProgress {
  const FileInspectionProgress({
    required this.stage,
    required this.current,
    required this.total,
    required this.codesFound,
    required this.source,
    required this.completed,
  });

  final FileInspectionStage stage;
  final int current;
  final int total;
  final int codesFound;
  final String source;
  final bool completed;
}

/// One already-selected raster unit. Paths are deliberately not copied into
/// records, logs, or evidence; only [source] becomes provenance.
class FileInspectionUnit {
  const FileInspectionUnit({required this.imagePath, required this.source});

  final String imagePath;
  final String source;
}

class FileInspectionResult {
  const FileInspectionResult({
    required this.records,
    required this.unitsInspected,
    required this.unitsWithoutCodes,
    required this.decodedCodes,
  });

  final List<ScanRecord> records;
  final int unitsInspected;
  final int unitsWithoutCodes;

  /// Number of non-empty payloads after per-unit deduplication.
  final int decodedCodes;
}

/// Testable orchestration for images and already-rasterized PDF pages.
///
/// Each unit is fully decoded, empty payloads are discarded, and identical
/// payloads are deduplicated only inside that unit. No persistence or external
/// action happens here. Cancellation throws before a result can be committed.
class FileInspectionCoordinator {
  const FileInspectionCoordinator({
    required this.decoder,
    this.decodeTimeout = FileInspectionLimits.decodeTimeout,
  });

  final FileCodeDecoder decoder;
  final Duration decodeTimeout;

  Future<FileInspectionResult> inspect(
    List<FileInspectionUnit> units, {
    CancellationToken? cancellationToken,
    void Function(FileInspectionProgress progress)? onProgress,
  }) async {
    final List<ScanRecord> records = <ScanRecord>[];
    int withoutCodes = 0;

    for (int index = 0; index < units.length; index++) {
      cancellationToken?.throwIfCancelled();
      final FileInspectionUnit unit = units[index];
      onProgress?.call(
        FileInspectionProgress(
          stage: FileInspectionStage.decoding,
          current: index + 1,
          total: units.length,
          codesFound: records.length,
          source: unit.source,
          completed: false,
        ),
      );

      final List<Barcode> decoded = await decoder
          .decode(unit.imagePath)
          .timeout(decodeTimeout);
      cancellationToken?.throwIfCancelled();
      final Map<String, Barcode> unique = <String, Barcode>{};
      for (final Barcode barcode in decoded) {
        final String payload = ScanRecord.payloadForBarcode(barcode);
        if (payload.isNotEmpty) unique.putIfAbsent(payload, () => barcode);
      }
      if (unique.isEmpty) withoutCodes++;
      final DateTime observedAt = DateTime.now();
      records.addAll(
        unique.values.map(
          (Barcode barcode) => ScanRecord.fromBarcode(
            barcode,
            source: unit.source,
            scannedAt: observedAt,
          ),
        ),
      );
      onProgress?.call(
        FileInspectionProgress(
          stage: FileInspectionStage.decoding,
          current: index + 1,
          total: units.length,
          codesFound: records.length,
          source: unit.source,
          completed: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    cancellationToken?.throwIfCancelled();
    return FileInspectionResult(
      records: List<ScanRecord>.unmodifiable(records),
      unitsInspected: units.length,
      unitsWithoutCodes: withoutCodes,
      decodedCodes: records.length,
    );
  }
}
