import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_detail_provider.dart';
import 'package:lead_tracker/src/leads/ui/sections/lead_actions_section.dart';
import 'package:lead_tracker/src/leads/ui/sections/lead_header_section.dart';
import 'package:lead_tracker/src/leads/ui/sections/lead_info_section.dart';
import 'package:lead_tracker/src/leads/ui/sections/lead_timeline_section.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_confirmation.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

@RoutePage()
class LeadDetailPage extends ConsumerWidget {
  const LeadDetailPage({@PathParam('id') required this.leadId, super.key});

  final int leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lead = ref.watch(leadDetailProvider(leadId));
    final current = lead.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(current?.name ?? 'Lead'),
        actions: [
          if (current != null) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.router.push(LeadFormRoute(leadId: leadId)),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _delete(context, ref, current);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete lead')),
              ],
            ),
          ],
        ],
      ),
      body: lead.unfold(
        (lead) => lead == null
            ? const AppEmptyWidget(
                icon: Icons.person_off_outlined,
                title: 'This lead no longer exists',
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: LeadHeaderSection(lead: lead)),
                  SliverToBoxAdapter(child: LeadActionsSection(lead: lead)),
                  SliverToBoxAdapter(child: LeadInfoSection(lead: lead)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                      child: Text('Activity', style: context.text.subtitle),
                    ),
                  ),
                  LeadTimelineSection(lead: lead),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
        onRetry: () => ref.invalidate(leadDetailProvider(leadId)),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Lead lead) async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Delete ${lead.name}?',
      message:
          'The lead is removed from your lists. Its calls and notes are '
          'kept, and you can undo right after.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    // Captured now: the undo runs after this screen is gone.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref.read(leadDetailProvider(leadId).notifier).delete();
    } on AppException catch (e) {
      e.message.showSnackBar();
      return;
    }
    if (context.mounted) {
      await context.router.maybePop();
    }
    '${lead.name} deleted'.showSnackBar(
      actionLabel: 'Undo',
      onAction: () async {
        // Keep the provider alive for the whole restore.
        final subscription = container.listen(
          leadDetailProvider(leadId).notifier,
          (_, _) {},
        );
        try {
          await subscription.read().restore();
        } on AppException catch (e) {
          e.message.showSnackBar();
        } finally {
          subscription.close();
        }
      },
    );
  }
}
