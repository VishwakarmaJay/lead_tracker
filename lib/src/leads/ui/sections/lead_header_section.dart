import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_detail_provider.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_labels.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// Name, company, and the status / temperature controls.
class LeadHeaderSection extends ConsumerWidget {
  const LeadHeaderSection({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(leadDetailProvider(lead.id).notifier);

    Future<void> run(Future<void> Function() change) async {
      try {
        await change();
      } on AppException catch (e) {
        e.message.showSnackBar();
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LeadAvatar(lead: lead),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.name, style: context.text.title),
                    if (lead.company != null)
                      Text(lead.company!, style: context.text.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Status', style: context.text.caption),
              const SizedBox(width: 12),
              DropdownButton<LeadStatus>(
                value: lead.status,
                underline: const SizedBox.shrink(),
                items: [
                  for (final status in LeadStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (status) {
                  if (status != null && status != lead.status) {
                    run(() => notifier.setStatus(status));
                  }
                },
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final temperature in LeadTemperature.values)
                ChoiceChip(
                  avatar: Icon(
                    temperature.icon,
                    size: 18,
                    color: temperature.color(context),
                  ),
                  label: Text(temperature.label),
                  selected: lead.temperature == temperature,
                  onSelected: (_) {
                    if (temperature != lead.temperature) {
                      run(() => notifier.setTemperature(temperature));
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
