import 'package:flutter/material.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';

/// Display text and icons for call enums.
extension CallTypeLabel on CallType {
  String get label => switch (this) {
    CallType.incoming => 'Incoming',
    CallType.outgoing => 'Outgoing',
    CallType.missed => 'Missed',
    CallType.rejected => 'Rejected',
    CallType.blocked => 'Blocked',
    CallType.unknown => 'Call',
  };

  IconData get icon => switch (this) {
    CallType.incoming => Icons.call_received,
    CallType.outgoing => Icons.call_made,
    CallType.missed => Icons.call_missed,
    CallType.rejected => Icons.call_end,
    CallType.blocked => Icons.block,
    CallType.unknown => Icons.call_outlined,
  };

  Color color(BuildContext context) => switch (this) {
    CallType.missed || CallType.rejected => context.colors.danger,
    CallType.blocked => context.colors.mutedText,
    _ => context.colors.primary,
  };
}

extension CallDispositionLabel on CallDisposition {
  String get label => switch (this) {
    CallDisposition.connected => 'Connected',
    CallDisposition.interested => 'Interested',
    CallDisposition.followUp => 'Follow up',
    CallDisposition.notInterested => 'Not interested',
    CallDisposition.noAnswer => 'No answer',
    CallDisposition.busy => 'Busy',
    CallDisposition.wrongNumber => 'Wrong number',
    CallDisposition.other => 'Other',
  };
}
