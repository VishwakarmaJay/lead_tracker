import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lead_detail_provider.g.dart';

/// One lead for the detail screen, plus quick edits.
/// `null` means the lead doesn't exist or was deleted.
@riverpod
class LeadDetail extends _$LeadDetail {
  @override
  Future<Lead?> build(int leadId) =>
      ref.watch(leadRepositoryProvider).getLeadById(leadId);

  Future<void> setStatus(LeadStatus status) =>
      _save((lead) => lead.copyWith(status: status));

  Future<void> setTemperature(LeadTemperature temperature) =>
      _save((lead) => lead.copyWith(temperature: temperature));

  /// Soft delete; calls, follow-ups, and recordings are kept.
  Future<void> delete() async {
    await ref.read(leadRepositoryProvider).deleteLead(leadId);
    _refresh();
  }

  Future<void> restore() async {
    await ref.read(leadRepositoryProvider).restoreLead(leadId);
    _refresh();
  }

  void _refresh() {
    ref
      ..refreshLeadViews(leadId: leadId, skipDetail: true)
      ..invalidateSelf();
  }

  Future<void> _save(Lead Function(Lead lead) change) async {
    final lead = state.value;
    if (lead == null) {
      return;
    }
    final updated = change(lead);
    // Optimistic: the chip changes immediately.
    state = AsyncData(updated);
    try {
      await ref.read(leadRepositoryProvider).updateLead(updated);
      ref.refreshLeadViews(leadId: leadId, skipDetail: true);
    } on Exception {
      // Put back what is really stored.
      ref.invalidateSelf();
      rethrow;
    }
  }
}
