import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/utils/formatters.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/ui/components/recording_player.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';

/// A recording in a lead's Activity list. Tap to open the player.
/// Public: used by the lead timeline.
class RecordingTile extends StatelessWidget {
  const RecordingTile({required this.recording, this.linkedCallAt, super.key});

  final CallRecording recording;

  /// When the linked call happened, if it is linked to one.
  final DateTime? linkedCallAt;

  @override
  Widget build(BuildContext context) {
    final duration = recording.durationMs;
    final title = duration == null
        ? 'Recording'
        : 'Recording · ${formatClock(Duration(milliseconds: duration))}';
    final details = linkedCallAt == null
        ? 'Saved ${formatDateTime(recording.importedAt)}'
        : 'From the call on ${formatDateTime(linkedCallAt!)}';
    final notes = recording.notes;

    return ListTile(
      onTap: () =>
          context.router.push(RecordingPlayerRoute(recordingId: recording.id)),
      leading: CircleAvatar(
        backgroundColor: context.colors.primary.withValues(alpha: 0.12),
        child: Icon(Icons.graphic_eq, color: context.colors.primary, size: 20),
      ),
      title: Text(title, style: context.text.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details, style: context.text.caption),
          if (notes != null) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              style: context.text.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      isThreeLine: notes != null,
      trailing: const Icon(Icons.play_circle_outline),
    );
  }
}
