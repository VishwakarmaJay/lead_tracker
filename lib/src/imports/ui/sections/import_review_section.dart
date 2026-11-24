import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/imports/data/import_preview.dart';
import 'package:lead_tracker/src/imports/providers/import_flow_provider.dart';

/// Counts, include options, and every row's outcome. Nothing is saved until
/// "Import".
class ImportReviewSection extends ConsumerWidget {
  const ImportReviewSection({required this.step, super.key});

  final ImportReview step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.read(importFlowProvider.notifier);
    final preview = step.preview;
    final options = step.options;
    final count = step.importCount;

    final unrecognised = preview.count(RowOutcome.unrecognisedPhone);
    final existing = preview.count(RowOutcome.existingDuplicate);
    final repeated = preview.count(RowOutcome.fileDuplicate);
    final invalid = preview.count(RowOutcome.invalid);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverList.list(
                  children: [
                    _CountRow(
                      icon: Icons.check_circle_outline,
                      color: context.colors.success,
                      label: 'Ready to import',
                      count: preview.count(RowOutcome.ready),
                    ),
                    if (unrecognised > 0)
                      _CountRow(
                        icon: Icons.help_outline,
                        color: context.colors.warning,
                        label: "Number can't be recognised",
                        count: unrecognised,
                        toggleLabel:
                            "Import these too (they won't be "
                            'matched to calls automatically)',
                        toggled: options.includeUnrecognisedPhones,
                        onToggle: (value) => flow.setOptions(
                          options.copyWith(includeUnrecognisedPhones: value),
                        ),
                      ),
                    if (existing > 0)
                      _CountRow(
                        icon: Icons.people_outline,
                        color: context.colors.warning,
                        label: 'Number already saved',
                        count: existing,
                        toggleLabel:
                            'Import as new leads anyway (saved '
                            'leads are never changed)',
                        toggled: options.includeExistingDuplicates,
                        onToggle: (value) => flow.setOptions(
                          options.copyWith(includeExistingDuplicates: value),
                        ),
                      ),
                    if (repeated > 0)
                      _CountRow(
                        icon: Icons.content_copy,
                        color: context.colors.mutedText,
                        label: 'Repeated in this file (skipped)',
                        count: repeated,
                      ),
                    if (invalid > 0)
                      _CountRow(
                        icon: Icons.error_outline,
                        color: context.colors.danger,
                        label: 'Missing name or phone (skipped)',
                        count: invalid,
                      ),
                    if (preview.emptyRows > 0)
                      _CountRow(
                        icon: Icons.remove,
                        color: context.colors.mutedText,
                        label: 'Blank rows (skipped)',
                        count: preview.emptyRows,
                      ),
                    const SizedBox(height: 16),
                    Text('Rows', style: context.text.subtitle),
                  ],
                ),
              ),
              SliverList.builder(
                itemCount: preview.candidates.length,
                itemBuilder: (context, index) {
                  final candidate = preview.candidates[index];
                  return _RowTile(
                    key: ValueKey(candidate.rowNumber),
                    candidate: candidate,
                    included: preview.isIncluded(candidate, options),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
        Material(
          elevation: 3,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: flow.backToMapping,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: count == 0 ? null : flow.confirmImport,
                      child: Text(
                        count == 0
                            ? 'Nothing to import'
                            : 'Import $count ${count == 1 ? 'lead' : 'leads'}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    this.toggleLabel,
    this.toggled = false,
    this.onToggle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final String? toggleLabel;
  final bool toggled;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: context.text.body)),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('$count', style: context.text.subtitle),
                ),
              ],
            ),
            if (toggleLabel != null && onToggle != null)
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 36),
                dense: true,
                value: toggled,
                onChanged: onToggle,
                title: Text(toggleLabel!, style: context.text.caption),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.candidate, required this.included, super.key});

  final ImportCandidate candidate;
  final bool included;

  @override
  Widget build(BuildContext context) {
    final draft = candidate.draft;
    final colors = context.colors;
    final (icon, color) = switch (candidate.outcome) {
      RowOutcome.ready => (Icons.check_circle_outline, colors.success),
      RowOutcome.unrecognisedPhone => (Icons.help_outline, colors.warning),
      RowOutcome.existingDuplicate => (Icons.people_outline, colors.warning),
      RowOutcome.fileDuplicate => (Icons.content_copy, colors.mutedText),
      RowOutcome.invalid => (Icons.error_outline, colors.danger),
    };
    final notes = [
      if (candidate.reason != null) candidate.reason!,
      if (candidate.warning != null) candidate.warning!,
    ];

    return Opacity(
      opacity: included ? 1 : 0.55,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color),
        title: Text(
          draft.name.isEmpty ? '(no name)' : draft.name,
          style: context.text.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            'Row ${candidate.rowNumber}',
            if (draft.phone.isNotEmpty) draft.phone,
            if (draft.company != null) draft.company!,
            ...notes,
          ].join(' · '),
          style: context.text.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          included ? 'Import' : 'Skip',
          style: context.text.caption.copyWith(
            color: included ? colors.success : colors.mutedText,
          ),
        ),
      ),
    );
  }
}
