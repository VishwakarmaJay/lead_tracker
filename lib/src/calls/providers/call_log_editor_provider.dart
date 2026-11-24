import 'package:flutter/foundation.dart';
import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'call_log_editor_provider.g.dart';

/// What the user entered in the "Log call" sheet.
@immutable
class CallLogInput {
  const CallLogInput({
    required this.leadId,
    required this.calledAt,
    this.callType = CallType.outgoing,
    this.durationSeconds = 0,
    this.disposition,
    this.summary,
    this.newTemperature,
  });

  final int leadId;
  final DateTime calledAt;
  final CallType callType;
  final int durationSeconds;

  /// Chosen by the user; never inferred.
  final CallDisposition? disposition;
  final String? summary;

  /// Optional: also update the lead's temperature.
  final LeadTemperature? newTemperature;
}

/// Saves a manual call log (and optionally the lead's temperature).
@riverpod
class CallLogEditor extends _$CallLogEditor {
  @override
  bool build() => false; // true while saving

  /// Creates a manual call, or updates [existing]. Returns the call id.
  Future<int> save(CallLogInput input, {CallLog? existing}) async {
    state = true;
    try {
      final calls = ref.read(callLogRepositoryProvider);
      final leads = ref.read(leadRepositoryProvider);
      final lead = await leads.getLeadById(input.leadId);
      final summary = input.summary?.trim();
      final cleanSummary = summary == null || summary.isEmpty ? null : summary;

      final int id;
      if (existing == null) {
        id = await calls.createCallLog(
          CallLogDraft(
            leadId: input.leadId,
            calledAt: input.calledAt,
            callType: input.callType,
            durationSeconds: input.durationSeconds,
            disposition: input.disposition,
            summary: cleanSummary,
            // Kept on the call so it still shows a number if the lead changes.
            phone: lead?.phone,
            phoneNormalized: lead?.phoneNormalized,
            displayName: lead?.name,
          ),
        );
      } else {
        id = existing.id;
        await calls.updateCallLog(
          existing.copyWith(
            leadId: () => input.leadId,
            calledAt: input.calledAt,
            callType: input.callType,
            durationSeconds: input.durationSeconds,
            disposition: () => input.disposition,
            summary: () => cleanSummary,
          ),
        );
      }

      final temperature = input.newTemperature;
      if (lead != null &&
          temperature != null &&
          temperature != lead.temperature) {
        await leads.updateLead(lead.copyWith(temperature: temperature));
      }

      ref.refreshLeadViews(leadId: input.leadId);
      if (existing?.leadId != null && existing!.leadId != input.leadId) {
        ref.refreshLeadViews(leadId: existing.leadId);
      }
      return id;
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}
