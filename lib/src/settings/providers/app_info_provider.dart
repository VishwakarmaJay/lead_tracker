import 'package:lead_tracker/core/instances/shorebird_instance.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_provider.g.dart';

/// Version details shown in Settings.
class AppInfo {
  const AppInfo({
    required this.version,
    required this.buildNumber,
    required this.shorebirdAvailable,
    this.patchNumber,
  });

  final String version;
  final String buildNumber;
  final bool shorebirdAvailable;

  /// Currently running Shorebird patch, or null for the base release.
  final int? patchNumber;

  String get label {
    final base = '$version ($buildNumber)';
    if (!shorebirdAvailable) {
      return '$base · updates off in this build';
    }
    return patchNumber == null ? base : '$base · patch $patchNumber';
  }
}

@riverpod
Future<AppInfo> appInfo(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  final codePush = ref.read(shorebirdProvider);
  final available = codePush.isShorebirdAvailable();
  return AppInfo(
    version: info.version,
    buildNumber: info.buildNumber,
    shorebirdAvailable: available,
    patchNumber: available ? await codePush.currentPatchNumber() : null,
  );
}
