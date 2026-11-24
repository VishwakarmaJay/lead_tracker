import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/instances/phone_launcher.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_call_provider.g.dart';

/// A call the user started from Lead Tracker and hasn't logged yet.
@immutable
class PendingCall {
  const PendingCall({
    required this.leadId,
    required this.leadName,
    required this.temperature,
    required this.dialedAt,
    this.leftApp = false,
  });

  final int leadId;
  final String leadName;
  final LeadTemperature temperature;
  final DateTime dialedAt;

  /// True once the app went to the background (the dialer opened).
  final bool leftApp;
}

/// Opens the dialer and remembers the call, so that when the user comes back
/// to Lead Tracker the home shell can offer to log it.
///
/// keepAlive: it must survive while the app sits in the background.
@Riverpod(keepAlive: true)
class PendingCallTracker extends _$PendingCallTracker {
  /// Calls older than this aren't offered for logging on return.
  static const maxAge = Duration(hours: 3);

  @override
  PendingCall? build() => null;

  /// Opens the dialer for [lead]. Returns false if no dialer app could open.
  Future<bool> dial(Lead lead) async {
    final opened = await ref
        .read(phoneLauncherProvider)
        .openDialer(phone: lead.phone, normalizedPhone: lead.phoneNormalized);
    if (opened) {
      state = PendingCall(
        leadId: lead.id,
        leadName: lead.name,
        temperature: lead.temperature,
        dialedAt: DateTime.now(),
      );
    }
    return opened;
  }

  /// Called when the app is hidden (the dialer is in front).
  void markLeftApp() {
    final pending = state;
    if (pending != null && !pending.leftApp) {
      state = PendingCall(
        leadId: pending.leadId,
        leadName: pending.leadName,
        temperature: pending.temperature,
        dialedAt: pending.dialedAt,
        leftApp: true,
      );
    }
  }

  /// Returns the call to offer for logging (and forgets it), or null.
  PendingCall? takeOnReturn({DateTime? now}) {
    final pending = state;
    if (pending == null || !pending.leftApp) {
      return null;
    }
    state = null;
    final age = (now ?? DateTime.now()).difference(pending.dialedAt);
    return age <= maxAge ? pending : null;
  }
}
