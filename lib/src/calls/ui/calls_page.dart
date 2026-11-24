import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/src/calls/providers/recent_calls_provider.dart';
import 'package:lead_tracker/src/calls/ui/components/call_log_tile.dart';
import 'package:lead_tracker/src/calls/ui/components/log_call_sheet.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_picker_sheet.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

/// Calls logged in Lead Tracker, newest first.
///
/// This is not the phone's call history: Lead Tracker only knows the calls
/// you log here (system call-log sync is Milestone 5, if the POC allows it).
@RoutePage()
class CallsPage extends ConsumerWidget {
  const CallsPage({super.key});

  Future<void> _logCall(BuildContext context) async {
    final lead = await showLeadPicker(context, title: 'Who did you call?');
    if (lead == null || !context.mounted) {
      return;
    }
    await showLogCallSheet(
      context,
      leadId: lead.id,
      leadName: lead.name,
      currentTemperature: lead.temperature,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(recentCallsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log-call',
        onPressed: () => _logCall(context),
        icon: const Icon(Icons.edit_note),
        label: const Text('Log call'),
      ),
      body: calls.unfold(
        (items) => items.isEmpty
            ? AppEmptyWidget(
                icon: Icons.call_outlined,
                title: 'No calls logged yet',
                message:
                    'Calls you log from a lead show up here. Lead '
                    "Tracker doesn't read your phone's call history.",
                action: OutlinedButton(
                  onPressed: () => _logCall(context),
                  child: const Text('Log a call'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final leadId = item.call.leadId;
                  final canOpen = leadId != null && !item.leadDeleted;
                  return CallLogTile(
                    key: ValueKey(item.call.id),
                    call: item.call,
                    leadName:
                        item.leadName ??
                        item.call.displayName ??
                        item.call.phone ??
                        'Unknown',
                    onTap: canOpen
                        ? () => context.router.push(
                            LeadDetailRoute(leadId: leadId),
                          )
                        : null,
                  );
                },
              ),
        onRetry: () => ref.invalidate(recentCallsProvider),
      ),
    );
  }
}
