import 'package:lead_tracker/src/calls/providers/lead_calls_provider.dart';
import 'package:lead_tracker/src/calls/providers/recent_calls_provider.dart';
import 'package:lead_tracker/src/leads/providers/lead_detail_provider.dart';
import 'package:lead_tracker/src/leads/providers/lead_list_provider.dart';
import 'package:lead_tracker/src/leads/providers/lead_timeline_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Re-reads every screen that shows lead or call data after a write.
///
/// A provider can't invalidate itself through `invalidate`; a notifier that
/// is one of these views passes `skipDetail` / `skipTimeline` and calls
/// `ref.invalidateSelf()` (or sets its own state) instead.
extension LeadRefresh on Ref {
  void refreshLeadViews({
    int? leadId,
    bool skipDetail = false,
    bool skipTimeline = false,
  }) {
    invalidate(leadListProvider);
    invalidate(leadSearchProvider);
    invalidate(recentCallsProvider);
    if (leadId != null) {
      if (!skipDetail) {
        invalidate(leadDetailProvider(leadId));
      }
      if (!skipTimeline) {
        invalidate(leadTimelineProvider(leadId));
      }
      invalidate(leadCallsProvider(leadId));
    }
  }
}
