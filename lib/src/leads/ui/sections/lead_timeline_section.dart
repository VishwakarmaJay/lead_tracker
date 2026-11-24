import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/calls/ui/components/call_log_tile.dart';
import 'package:lead_tracker/src/calls/ui/components/log_call_sheet.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_timeline_provider.dart';
import 'package:lead_tracker/src/shared/components/app_confirmation.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// The lead's calls, newest first (a sliver).
class LeadTimelineSection extends ConsumerWidget {
  const LeadTimelineSection({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(leadTimelineProvider(lead.id));
    final calls = timeline.value;
    if (calls == null || (timeline.hasError && !timeline.isLoading)) {
      // Loading or error: unfold renders the loader / error box.
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 160,
          child: timeline.unfold(
            (_) => const SizedBox.shrink(),
            onRetry: () => ref.invalidate(leadTimelineProvider(lead.id)),
          ),
        ),
      );
    }
    if (calls.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyWidget(
          icon: Icons.history,
          title: 'No calls yet',
          message: 'Tap Call, then log what was discussed when you come back.',
        ),
      );
    }
    return SliverList.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return CallLogTile(
          key: ValueKey(call.id),
          call: call,
          onTap: () => _edit(context, call),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => value == 'delete'
                ? _delete(context, ref, call)
                : _edit(context, call),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        );
      },
    );
  }

  void _edit(BuildContext context, CallLog call) {
    showLogCallSheet(
      context,
      leadId: lead.id,
      leadName: lead.name,
      existing: call,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CallLog call,
  ) async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Delete this call?',
      message: 'The call and its summary are removed from Lead Tracker.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref
          .read(leadTimelineProvider(lead.id).notifier)
          .deleteCall(call.id);
    } on AppException catch (e) {
      e.message.showSnackBar();
    }
  }
}
