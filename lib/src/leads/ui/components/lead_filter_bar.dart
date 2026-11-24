import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_list_provider.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_labels.dart';

/// Status and temperature filter chips under the search field.
class LeadFilterBar extends ConsumerWidget {
  const LeadFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(leadListFilterProvider);
    final notifier = ref.read(leadListFilterProvider.notifier);
    final hasFilter = filter.status != null || filter.temperature != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          FilterChip(
            label: Text(filter.status?.label ?? 'Status'),
            selected: filter.status != null,
            onSelected: (_) async {
              final choice = await _pick<LeadStatus>(
                context,
                title: 'Filter by status',
                options: LeadStatus.values,
                current: filter.status,
                label: (s) => s.label,
              );
              if (choice != null) {
                notifier.setStatus(choice.value);
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: filter.temperature == null
                ? null
                : Icon(
                    filter.temperature!.icon,
                    size: 18,
                    color: filter.temperature!.color(context),
                  ),
            label: Text(filter.temperature?.label ?? 'Temperature'),
            selected: filter.temperature != null,
            onSelected: (_) async {
              final choice = await _pick<LeadTemperature>(
                context,
                title: 'Filter by temperature',
                options: LeadTemperature.values,
                current: filter.temperature,
                label: (t) => t.label,
              );
              if (choice != null) {
                notifier.setTemperature(choice.value);
              }
            },
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: notifier.clearFilters,
              child: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wraps the picked option so "Any" (null) can be told apart from dismissing.
class _Choice<T> {
  const _Choice(this.value);

  final T? value;
}

Future<_Choice<T>?> _pick<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T? current,
  required String Function(T) label,
}) {
  return showModalBottomSheet<_Choice<T>>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(title, style: context.text.subtitle),
          ),
          ListTile(
            title: const Text('Any'),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(_Choice<T>(null)),
          ),
          for (final option in options)
            ListTile(
              title: Text(label(option)),
              trailing: option == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(_Choice<T>(option)),
            ),
        ],
      ),
    ),
  );
}
