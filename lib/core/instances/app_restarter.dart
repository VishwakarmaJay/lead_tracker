import 'package:restart_app/restart_app.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_restarter.g.dart';

/// Relaunches the app in a **new native process**.
///
/// Shorebird only boots a downloaded patch on a fresh process start.
/// `RestartMode.platformDefault` recreates the activity in the same process,
/// so the patch would be skipped; `RestartMode.process` starts a new task and
/// then kills the current process.
class AppRestarter {
  const AppRestarter();

  Future<bool> restartProcess() async {
    final result = await Restart.restartApp(mode: RestartMode.process);
    return result.success;
  }
}

@Riverpod(keepAlive: true)
AppRestarter appRestarter(Ref ref) => const AppRestarter();
