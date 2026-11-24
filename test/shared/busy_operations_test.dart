import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/shared/providers/busy_operations_provider.dart';

void main() {
  test(
    'counts while running and resets even when the operation fails',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final busy = container.read(busyOperationsProvider.notifier);

      final future = busy.track(() async {
        expect(container.read(busyOperationsProvider), 1);
        throw Exception('copy failed');
      });

      await expectLater(future, throwsException);
      expect(container.read(busyOperationsProvider), 0);
    },
  );
}
