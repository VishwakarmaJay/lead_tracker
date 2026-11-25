import 'package:flutter/foundation.dart';
import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:lead_tracker/src/recordings/data/call_recording_repository.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lead_timeline_provider.g.dart';

/// One item in a lead's Activity list.
sealed class TimelineEntry {
  const TimelineEntry();

  /// When it happened, for ordering.
  DateTime get at;
}

@immutable
class TimelineCall extends TimelineEntry {
  const TimelineCall(this.call, {this.hasRecording = false});

  final CallLog call;

  /// A recording is linked to this call.
  final bool hasRecording;

  @override
  DateTime get at => call.calledAt;
}

@immutable
class TimelineRecording extends TimelineEntry {
  const TimelineRecording(this.recording, {this.linkedCall});

  final CallRecording recording;
  final CallLog? linkedCall;

  /// A recording linked to a call sits next to that call; otherwise it is
  /// placed at its import time.
  @override
  DateTime get at => linkedCall?.calledAt ?? recording.importedAt;
}

/// Merges calls and recordings, newest first. A recording linked to a call
/// is placed just above that call.
List<TimelineEntry> buildTimeline(
  List<CallLog> calls,
  List<CallRecording> recordings,
) {
  final callsById = {for (final call in calls) call.id: call};
  final recordedCallIds = {
    for (final recording in recordings) recording.callLogId,
  };
  final entries =
      <TimelineEntry>[
        for (final call in calls)
          TimelineCall(call, hasRecording: recordedCallIds.contains(call.id)),
        for (final recording in recordings)
          TimelineRecording(
            recording,
            linkedCall: callsById[recording.callLogId],
          ),
      ]..sort((a, b) {
        final byTime = b.at.compareTo(a.at);
        if (byTime != 0) {
          return byTime;
        }
        // Same moment: the recording first, then its call.
        return (a is TimelineRecording ? 0 : 1) -
            (b is TimelineRecording ? 0 : 1);
      });
  return entries;
}

/// A lead's activity, newest first: calls and recordings. Follow-ups
/// (Milestone 6) join it later.
@riverpod
class LeadTimeline extends _$LeadTimeline {
  @override
  Future<List<TimelineEntry>> build(int leadId) async {
    final calls = ref.watch(callLogRepositoryProvider).listForLead(leadId);
    final recordings = ref
        .watch(callRecordingRepositoryProvider)
        .listForLead(leadId);
    return buildTimeline(await calls, await recordings);
  }

  Future<void> deleteCall(int callLogId) async {
    await ref.read(callLogRepositoryProvider).deleteCallLog(callLogId);
    ref
      ..refreshLeadViews(leadId: leadId, skipTimeline: true)
      ..invalidateSelf();
  }
}
