import 'package:flutter/material.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/utils/formatters.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/calls/ui/components/call_labels.dart';

/// One call in a list: type icon, outcome, summary, time, duration.
/// Public: the lead timeline uses it too (see calls/MODULE.md).
class CallLogTile extends StatelessWidget {
  const CallLogTile({
    required this.call,
    this.leadName,
    this.onTap,
    this.trailing,
    super.key,
  });

  final CallLog call;

  /// Shown as the title on the Calls tab; null on a lead's own timeline.
  final String? leadName;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final outcome = call.disposition?.label ?? call.callType.label;
    final details = [
      formatDateTime(call.calledAt),
      if (call.durationSeconds > 0) formatCallDuration(call.durationSeconds),
    ].join(' · ');
    final summary = call.summary;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: call.callType.color(context).withValues(alpha: 0.12),
        child: Icon(
          call.callType.icon,
          color: call.callType.color(context),
          size: 20,
        ),
      ),
      title: Text(
        leadName == null ? outcome : '$leadName · $outcome',
        style: context.text.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details, style: context.text.caption),
          if (summary != null) ...[
            const SizedBox(height: 4),
            Text(
              summary,
              style: context.text.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: trailing,
      isThreeLine: summary != null,
    );
  }
}
