import 'package:lead_tracker/core/instances/phone_launcher.dart';

/// Records every URI the app tries to open.
class FakeOpener {
  FakeOpener({this.succeeds = true});

  bool succeeds;
  final opened = <Uri>[];

  Future<bool> call(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }

  PhoneLauncher get launcher => PhoneLauncher(open: call);
}
