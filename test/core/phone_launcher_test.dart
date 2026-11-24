import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_launcher.dart';

void main() {
  test('dialer uses the normalised number when there is one', () async {
    final opener = FakeOpener();
    await opener.launcher.openDialer(
      phone: '98765 43210',
      normalizedPhone: '+919876543210',
    );
    expect(opener.opened.single.toString(), 'tel:+919876543210');
  });

  test('dialer falls back to the typed number without spaces', () async {
    final opener = FakeOpener();
    await opener.launcher.openDialer(phone: '(022) 2345-6789 ext');
    expect(opener.opened.single.toString(), 'tel:02223456789');
  });

  test('dialer refuses a number with no digits', () async {
    final opener = FakeOpener();
    expect(await opener.launcher.openDialer(phone: 'n/a'), isFalse);
    expect(opener.opened, isEmpty);
  });

  test('WhatsApp opens wa.me with digits only', () async {
    final opener = FakeOpener();
    await opener.launcher.openWhatsApp('+919876543210');
    expect(opener.opened.single.toString(), 'https://wa.me/919876543210');
  });

  test('reports when no app could open the link', () async {
    final opener = FakeOpener(succeeds: false);
    expect(await opener.launcher.openDialer(phone: '9876543210'), isFalse);
  });
}
