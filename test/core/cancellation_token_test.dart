import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_qr_inspector/core/performance/cancellation_token.dart';

void main() {
  test('cancellation token stops batch work deterministically', () {
    final CancellationToken token = CancellationToken();
    expect(token.isCancelled, isFalse);
    token.cancel();
    expect(token.isCancelled, isTrue);
    expect(token.throwIfCancelled, throwsA(isA<OperationCancelledException>()));
  });

  test('batch progress reports a bounded fraction', () {
    final BatchProgress progress = BatchProgress();
    progress.update(current: 3, total: 10);
    expect(progress.fraction, 0.3);
  });
}
