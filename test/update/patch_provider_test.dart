import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/app_restarter.dart';
import 'package:lead_tracker/core/instances/shorebird_instance.dart';
import 'package:lead_tracker/src/update/providers/patch_provider.dart';

import 'fakes.dart';

void main() {
  // Patch shows snack bars through a GlobalKey, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(
    FakeShorebird shorebird, [
    FakeRestarter? restarter,
  ]) {
    final container = ProviderContainer(
      overrides: [
        shorebirdProvider.overrideWithValue(shorebird),
        appRestarterProvider.overrideWithValue(restarter ?? FakeRestarter()),
      ],
    );
    addTearDown(container.dispose);
    // Keep the auto-dispose provider alive for the whole test.
    container.listen(patchProvider, (_, _) {});
    return container;
  }

  test('hidden when Shorebird is unavailable (debug builds)', () async {
    final container = containerWith(FakeShorebird(available: false));
    expect(await container.read(patchProvider.future), PatchStatus.hidden);
  });

  test('hidden when there is no patch', () async {
    final container = containerWith(FakeShorebird());
    expect(await container.read(patchProvider.future), PatchStatus.hidden);
  });

  test('hidden when the patch check fails (offline)', () async {
    final container = containerWith(FakeShorebird(throwOnCheck: true));
    expect(await container.read(patchProvider.future), PatchStatus.hidden);
  });

  test('available when a patch can be downloaded', () async {
    final container = containerWith(FakeShorebird(availableForDownload: true));
    expect(await container.read(patchProvider.future), PatchStatus.available);
  });

  test('readyToRestart when a patch is already staged', () async {
    final container = containerWith(
      FakeShorebird(readyToInstall: true, availableForDownload: true),
    );
    expect(
      await container.read(patchProvider.future),
      PatchStatus.readyToRestart,
    );
  });

  test('download moves available -> readyToRestart', () async {
    final shorebird = FakeShorebird(availableForDownload: true);
    final container = containerWith(shorebird);
    await container.read(patchProvider.future);

    await container.read(patchProvider.notifier).download();

    expect(shorebird.downloads, 1);
    expect(container.read(patchProvider).value, PatchStatus.readyToRestart);
  });

  test(
    'failed download goes back to available so the user can retry',
    () async {
      final container = containerWith(
        FakeShorebird(availableForDownload: true, downloadSucceeds: false),
      );
      await container.read(patchProvider.future);

      await container.read(patchProvider.notifier).download();

      expect(container.read(patchProvider).value, PatchStatus.available);
    },
  );

  test('restart relaunches the process', () async {
    final restarter = FakeRestarter();
    final container = containerWith(
      FakeShorebird(readyToInstall: true),
      restarter,
    );
    await container.read(patchProvider.future);

    await container.read(patchProvider.notifier).restart();

    expect(restarter.calls, 1);
  });
}
