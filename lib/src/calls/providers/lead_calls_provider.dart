import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lead_calls_provider.g.dart';

/// A lead's calls, newest first — for "link this recording to a call".
@riverpod
Future<List<CallLog>> leadCalls(Ref ref, int leadId) =>
    ref.watch(callLogRepositoryProvider).listForLead(leadId);
