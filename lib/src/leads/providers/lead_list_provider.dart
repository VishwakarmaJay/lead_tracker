import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lead_list_provider.g.dart';

/// Search text and filters of the Leads tab.
@riverpod
class LeadListFilter extends _$LeadListFilter {
  @override
  LeadQuery build() => const LeadQuery();

  void setText(String text) => state = LeadQuery(
    text: text.trim().isEmpty ? null : text.trim(),
    status: state.status,
    temperature: state.temperature,
  );

  void setStatus(LeadStatus? status) => state = LeadQuery(
    text: state.text,
    status: status,
    temperature: state.temperature,
  );

  void setTemperature(LeadTemperature? temperature) => state = LeadQuery(
    text: state.text,
    status: state.status,
    temperature: temperature,
  );

  void clearFilters() => state = LeadQuery(text: state.text);
}

/// Leads matching the current filter.
@riverpod
Future<List<Lead>> leadList(Ref ref) {
  final query = ref.watch(leadListFilterProvider);
  return ref.watch(leadRepositoryProvider).searchLeads(query);
}

/// Leads matching [text], for the lead picker (log a call, attach a
/// recording). Active leads only.
@riverpod
Future<List<Lead>> leadSearch(Ref ref, String text) {
  final trimmed = text.trim();
  return ref
      .watch(leadRepositoryProvider)
      .searchLeads(
        LeadQuery(text: trimmed.isEmpty ? null : trimmed, limit: 50),
      );
}
