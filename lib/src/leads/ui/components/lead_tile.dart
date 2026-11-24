import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/calls/providers/pending_call_provider.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_labels.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// One row on the Leads tab: avatar, name, company/phone, status, call button.
class LeadTile extends ConsumerWidget {
  const LeadTile({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [lead.company, lead.phone].whereType<String>().join(' · ');
    return ListTile(
      onTap: () => context.router.push(LeadDetailRoute(leadId: lead.id)),
      leading: LeadAvatar(lead: lead),
      title: Text(
        lead.name,
        style: context.text.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            LabelPill(text: lead.status.label),
            const SizedBox(width: 8),
            if (lead.phoneNormalized == null) ...[
              Tooltip(
                message: 'Phone number not recognised',
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: context.colors.warning,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                subtitle,
                style: context.text.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        tooltip: 'Call ${lead.name}',
        icon: Icon(Icons.call, color: context.colors.primary),
        onPressed: () async {
          final opened = await ref
              .read(pendingCallTrackerProvider.notifier)
              .dial(lead);
          if (!opened) {
            'No phone app could open this number.'.showSnackBar();
          }
        },
      ),
    );
  }
}
