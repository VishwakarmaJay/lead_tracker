import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/phone_launcher.dart';
import 'package:lead_tracker/src/calls/providers/pending_call_provider.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';

import '../helpers/fake_launcher.dart';

final _lead = Lead(
  id: 7,
  name: 'Asha',
  phone: '98765 43210',
  phoneNormalized: '+919876543210',
  status: LeadStatus.newLead,
  temperature: LeadTemperature.warm,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  (ProviderContainer, FakeOpener) setUpTracker({bool opens = true}) {
    final opener = FakeOpener(succeeds: opens);
    final container = ProviderContainer(
      overrides: [phoneLauncherProvider.overrideWithValue(opener.launcher)],
    );
    addTearDown(container.dispose);
    return (container, opener);
  }

  test('dial opens the dialer and offers logging after returning', () async {
    final (container, opener) = setUpTracker();
    final tracker = container.read(pendingCallTrackerProvider.notifier);

    expect(await tracker.dial(_lead), isTrue);
    expect(opener.opened.single.toString(), 'tel:+919876543210');

    tracker.markLeftApp();
    final pending = tracker.takeOnReturn();
    expect(pending?.leadId, 7);
    expect(pending?.temperature, LeadTemperature.warm);
    // Offered once only.
    expect(tracker.takeOnReturn(), isNull);
  });

  test('no prompt if the app never went to the background', () async {
    final (container, _) = setUpTracker();
    final tracker = container.read(pendingCallTrackerProvider.notifier);
    await tracker.dial(_lead);
    expect(tracker.takeOnReturn(), isNull);
  });

  test('no prompt when the dialer could not open', () async {
    final (container, _) = setUpTracker(opens: false);
    final tracker = container.read(pendingCallTrackerProvider.notifier);
    expect(await tracker.dial(_lead), isFalse);
    tracker.markLeftApp();
    expect(tracker.takeOnReturn(), isNull);
  });

  test('no prompt for a call started hours ago', () async {
    final (container, _) = setUpTracker();
    final tracker = container.read(pendingCallTrackerProvider.notifier);
    await tracker.dial(_lead);
    tracker.markLeftApp();
    final later = DateTime.now().add(
      PendingCallTracker.maxAge + const Duration(minutes: 1),
    );
    expect(tracker.takeOnReturn(now: later), isNull);
  });
}
