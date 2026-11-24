import 'package:lead_tracker/core/extension/log.dart';
import 'package:lead_tracker/core/instances/app_restarter.dart';
import 'package:lead_tracker/core/instances/shorebird_instance.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patch_provider.g.dart';

/// Lifecycle of the update banner (same flow as hedged's `src/update`).
///
/// A Shorebird patch is never swapped into the running Dart code. It only
/// loads on a fresh process start, so the banner walks the user through
/// download → restart.
enum PatchStatus {
  /// No patch pending, or Shorebird unavailable (debug builds). Banner hidden.
  hidden,

  /// A patch can be downloaded.
  available,

  /// Download in progress.
  downloading,

  /// Patch is on disk and only needs a restart.
  readyToRestart,
}

@riverpod
class Patch extends _$Patch {
  @override
  Future<PatchStatus> build() async {
    final codePush = ref.read(shorebirdProvider);
    if (!codePush.isShorebirdAvailable()) {
      return PatchStatus.hidden;
    }
    try {
      // Shorebird's auto-update may already have downloaded a patch in the
      // background on launch; then only a restart is needed.
      if (await codePush.isNewPatchReadyToInstall()) {
        return PatchStatus.readyToRestart;
      }
      if (await codePush.isNewPatchAvailableForDownload()) {
        return PatchStatus.available;
      }
    } on Exception catch (e) {
      // Offline or Shorebird unreachable: "no update right now".
      'Patch check failed: ${e.runtimeType}'.logWarning();
    }
    return PatchStatus.hidden;
  }

  /// Downloads the patch, then moves to [PatchStatus.readyToRestart].
  ///
  /// Success is confirmed with `isNewPatchReadyToInstall` rather than assumed,
  /// so the user is never sent into a restart that has nothing to apply.
  Future<void> download() async {
    final codePush = ref.read(shorebirdProvider);
    state = const AsyncData(PatchStatus.downloading);
    try {
      await codePush.downloadUpdateIfAvailable();
      final ready = await codePush.isNewPatchReadyToInstall();
      state = AsyncData(
        ready ? PatchStatus.readyToRestart : PatchStatus.hidden,
      );
    } on Exception catch (e) {
      'Patch download failed: ${e.runtimeType}'.logWarning();
      'Could not download the update. Check your connection and try again.'
          .showSnackBar();
      state = const AsyncData(PatchStatus.available);
    }
  }

  /// Applies the downloaded patch by relaunching the app process.
  Future<void> restart() async {
    final ok = await ref.read(appRestarterProvider).restartProcess();
    if (!ok) {
      'Could not restart automatically. Close and reopen the app to finish '
              'updating.'
          .showSnackBar(duration: const Duration(seconds: 8));
    }
  }
}
