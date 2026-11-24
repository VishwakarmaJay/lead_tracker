import 'package:lead_tracker/core/instances/app_restarter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class FakeShorebird implements ShorebirdCodePush {
  FakeShorebird({
    this.available = true,
    this.readyToInstall = false,
    this.availableForDownload = false,
    this.downloadSucceeds = true,
    this.throwOnCheck = false,
  });

  bool available;
  bool readyToInstall;
  bool availableForDownload;
  bool downloadSucceeds;
  bool throwOnCheck;
  int downloads = 0;

  @override
  bool isShorebirdAvailable() => available;

  @override
  Future<bool> isNewPatchReadyToInstall() async {
    if (throwOnCheck) {
      throw Exception('offline');
    }
    return readyToInstall;
  }

  @override
  Future<bool> isNewPatchAvailableForDownload() async {
    if (throwOnCheck) {
      throw Exception('offline');
    }
    return availableForDownload;
  }

  @override
  Future<void> downloadUpdateIfAvailable() async {
    downloads++;
    if (!downloadSucceeds) {
      throw Exception('network');
    }
    readyToInstall = true;
  }

  @override
  Future<int?> currentPatchNumber() async => null;

  @override
  Future<int?> nextPatchNumber() async => null;
}

class FakeRestarter implements AppRestarter {
  FakeRestarter({this.succeeds = true});

  final bool succeeds;
  int calls = 0;

  @override
  Future<bool> restartProcess() async {
    calls++;
    return succeeds;
  }
}
