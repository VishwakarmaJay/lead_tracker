import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'phone_launcher.g.dart';

typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> _openExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Opens the phone's own apps. Lead Tracker never places or records calls:
/// `tel:` only opens the dialer with the number filled in, and the user
/// presses call there. No `CALL_PHONE` permission.
class PhoneLauncher {
  const PhoneLauncher({UrlOpener open = _openExternally}) : _open = open;

  final UrlOpener _open;

  static final _dialable = RegExp(r'[^\d+*#,;]');

  /// Opens the dialer. Prefers the normalised number when there is one.
  /// Returns false when no dialer app could open it.
  Future<bool> openDialer({required String phone, String? normalizedPhone}) {
    final number = normalizedPhone ?? phone.replaceAll(_dialable, '');
    if (number.isEmpty) {
      return Future.value(false);
    }
    return _open(Uri(scheme: 'tel', path: number));
  }

  /// Opens a WhatsApp chat via `https://wa.me/<digits>`. Only for numbers that
  /// normalised cleanly; nothing is sent automatically.
  Future<bool> openWhatsApp(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return Future.value(false);
    }
    return _open(Uri.https('wa.me', '/$digits'));
  }
}

@riverpod
PhoneLauncher phoneLauncher(Ref ref) => const PhoneLauncher();
