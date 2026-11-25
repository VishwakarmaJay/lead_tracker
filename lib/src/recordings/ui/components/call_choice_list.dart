import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/utils/formatters.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/calls/providers/lead_calls_provider.dart';
import 'package:lead_tracker/src/calls/ui/components/call_labels.dart';

/// "Don't link" plus the lead's most recent calls; one can be chosen.
class CallChoiceList extends ConsumerWidget {
  const CallChoiceList({
    required this.leadId,
    required this.selectedCallId,
    required this.onChanged,
    this.limit = 5,
    super.key,
  });

  final int leadId;
  final int? selectedCallId;
  final ValueChanged<int?> onChanged;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(leadCallsProvider(leadId)).value ?? const [];
    Widget option(String title, int? id, {String? subtitle}) {
      final selected = selectedCallId == id;
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? context.colors.primary : context.colors.mutedText,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        onTap: () => onChanged(id),
      );
    }

    return Column(
      children: [
        option("Don't link to a call", null),
        for (final call in calls.take(limit))
          option(
            formatDateTime(call.calledAt),
            call.id,
            subtitle: _describe(call),
          ),
        if (calls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No calls logged for this lead yet.',
                style: context.text.caption,
              ),
            ),
          ),
      ],
    );
  }

  static String _describe(CallLog call) {
    final summary = call.summary;
    final outcome = call.disposition?.label ?? call.callType.label;
    return summary == null ? outcome : '$outcome · $summary';
  }
}
