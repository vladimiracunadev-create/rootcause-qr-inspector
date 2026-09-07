import 'package:rootcause_qr_inspector/models/scan_record.dart';

/// Single, testable policy for automatic scan-history persistence.
abstract final class ScanPersistencePolicy {
  static List<ScanRecord> eligible(Iterable<ScanRecord> records) => records
      .where((ScanRecord record) => !record.isSensitive)
      .toList(growable: false);
}
