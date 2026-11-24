import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lead_timeline_provider.g.dart';

/// A lead's activity, newest first. Milestone 2: call logs. Recordings
/// (Milestone 4) and follow-ups (Milestone 6) join it later.
@riverpod
class LeadTimeline extends _$LeadTimeline {
  @override
  Future<List<CallLog>> build(int leadId) =>
      ref.watch(callLogRepositoryProvider).listForLead(leadId);

  Future<void> deleteCall(int callLogId) async {
    await ref.read(callLogRepositoryProvider).deleteCallLog(callLogId);
    ref
      ..refreshLeadViews(leadId: leadId, skipTimeline: true)
      ..invalidateSelf();
  }
}
