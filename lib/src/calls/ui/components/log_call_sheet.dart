import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/utils/formatters.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/calls/providers/call_log_editor_provider.dart';
import 'package:lead_tracker/src/calls/ui/components/call_labels.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_labels.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// Opens the "Log call" sheet. Returns true when a call was saved.
///
/// Public: used by the lead detail screen, the Calls tab, and the
/// after-call prompt in the home shell (see calls/MODULE.md).
Future<bool> showLogCallSheet(
  BuildContext context, {
  required int leadId,
  required String leadName,
  LeadTemperature? currentTemperature,
  CallLog? existing,
  DateTime? calledAt,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LogCallSheet(
      leadId: leadId,
      leadName: leadName,
      currentTemperature: currentTemperature,
      existing: existing,
      calledAt: calledAt,
    ),
  );
  return saved ?? false;
}

class _LogCallSheet extends ConsumerStatefulWidget {
  const _LogCallSheet({
    required this.leadId,
    required this.leadName,
    this.currentTemperature,
    this.existing,
    this.calledAt,
  });

  final int leadId;
  final String leadName;
  final LeadTemperature? currentTemperature;
  final CallLog? existing;
  final DateTime? calledAt;

  @override
  ConsumerState<_LogCallSheet> createState() => _LogCallSheetState();
}

class _LogCallSheetState extends ConsumerState<_LogCallSheet> {
  static const _commonTypes = [
    CallType.outgoing,
    CallType.incoming,
    CallType.missed,
  ];

  late DateTime _calledAt;
  late CallType _callType;
  CallDisposition? _disposition;
  LeadTemperature? _temperature;
  late final TextEditingController _minutes;
  late final TextEditingController _summary;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _calledAt = (existing?.calledAt ?? widget.calledAt ?? DateTime.now())
        .toLocal();
    _callType = existing?.callType ?? CallType.outgoing;
    _disposition = existing?.disposition;
    _temperature = widget.currentTemperature;
    final minutes = (existing?.durationSeconds ?? 0) ~/ 60;
    _minutes = TextEditingController(text: minutes > 0 ? '$minutes' : '');
    _summary = TextEditingController(text: existing?.summary ?? '');
  }

  @override
  void dispose() {
    _minutes.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _calledAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_calledAt),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _calledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final minutes = int.tryParse(_minutes.text.trim()) ?? 0;
    try {
      await ref
          .read(callLogEditorProvider.notifier)
          .save(
            CallLogInput(
              leadId: widget.leadId,
              calledAt: _calledAt,
              callType: _callType,
              durationSeconds: minutes * 60,
              disposition: _disposition,
              summary: _summary.text,
              newTemperature: widget.existing == null ? _temperature : null,
            ),
            existing: widget.existing,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      e.message.showSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(callLogEditorProvider);
    final isNew = widget.existing == null;
    final types = {..._commonTypes, _callType}.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isNew ? 'Log call' : 'Edit call', style: context.text.title),
            Text(widget.leadName, style: context.text.bodyMuted),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(formatDateTime(_calledAt)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickWhen,
            ),
            const SizedBox(height: 8),
            SegmentedButton<CallType>(
              segments: [
                for (final type in types)
                  ButtonSegment(
                    value: type,
                    icon: Icon(type.icon),
                    label: Text(type.label),
                  ),
              ],
              selected: {_callType},
              onSelectionChanged: (selection) =>
                  setState(() => _callType = selection.first),
            ),
            const SizedBox(height: 20),
            Text('Outcome', style: context.text.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final disposition in CallDisposition.values)
                  ChoiceChip(
                    label: Text(disposition.label),
                    selected: _disposition == disposition,
                    onSelected: (selected) => setState(
                      () => _disposition = selected ? disposition : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _summary,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What was discussed?',
                hintText: 'Budget, requirements, what you promised…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes, optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (isNew && widget.currentTemperature != null) ...[
              const SizedBox(height: 20),
              Text('Lead temperature', style: context.text.label),
              const SizedBox(height: 8),
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
                      selected: _temperature == temperature,
                      onSelected: (_) =>
                          setState(() => _temperature = temperature),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : _save,
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
