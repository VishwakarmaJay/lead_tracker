import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

part 'shorebird_instance.g.dart';

/// The Shorebird code-push client for the session.
///
/// In debug builds (and any build not made with `shorebird release`)
/// `isShorebirdAvailable()` is false and every call is a no-op.
@Riverpod(keepAlive: true)
ShorebirdCodePush shorebird(Ref ref) => ShorebirdCodePush();
