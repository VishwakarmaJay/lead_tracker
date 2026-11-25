import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/instances/phone_launcher.dart';
import 'package:lead_tracker/src/calls/providers/pending_call_provider.dart';
import 'package:lead_tracker/src/calls/ui/components/log_call_sheet.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/recordings/ui/shared_inbox_page.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// Call, WhatsApp, and Log call buttons.
class LeadActionsSection extends ConsumerWidget {
  const LeadActionsSection({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalized = lead.phoneNormalized;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () async {
              final opened = await ref
                  .read(pendingCallTrackerProvider.notifier)
                  .dial(lead);
              if (!opened) {
                'No phone app could open this number.'.showSnackBar();
              }
            },
            icon: const Icon(Icons.call),
            label: const Text('Call'),
          ),
          // Only for numbers that normalised cleanly; never sends anything.
          if (normalized != null)
            OutlinedButton.icon(
              onPressed: () async {
                final opened = await ref
                    .read(phoneLauncherProvider)
                    .openWhatsApp(normalized);
                if (!opened) {
                  'WhatsApp could not be opened.'.showSnackBar();
                }
              },
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
          OutlinedButton.icon(
            onPressed: () => showLogCallSheet(
              context,
              leadId: lead.id,
              leadName: lead.name,
              currentTemperature: lead.temperature,
            ),
            icon: const Icon(Icons.edit_note),
            label: const Text('Log call'),
          ),
          // Fallback when sharing from Google Phone isn't possible.
          OutlinedButton.icon(
            onPressed: () => pickAudioAndImport(context, ref, leadId: lead.id),
            icon: const Icon(Icons.audio_file_outlined),
            label: const Text('Add recording'),
          ),
        ],
      ),
    );
  }
}
