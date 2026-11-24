import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_calls_provider.g.dart';

/// Calls tab: newest calls with their lead's name.
@riverpod
Future<List<CallLogWithLead>> recentCalls(Ref ref) =>
    ref.watch(callLogRepositoryProvider).listRecentWithLeads();
