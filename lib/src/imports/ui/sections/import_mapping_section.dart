import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';
import 'package:lead_tracker/src/imports/data/spreadsheet.dart';
import 'package:lead_tracker/src/imports/providers/import_flow_provider.dart';

/// Pick the sheet (XLSX) and which column fills each lead field.
class ImportMappingSection extends ConsumerWidget {
  const ImportMappingSection({required this.step, super.key});

  final ImportMapping step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.read(importFlowProvider.notifier);
    final sheet = step.sheet;
    final sheets = step.workbook.sheets;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(step.fileName, style: context.text.subtitle),
              const SizedBox(height: 4),
              Text(
                '${sheet.rows.length} rows with data',
                style: context.text.bodyMuted,
              ),
              if (sheets.length > 1) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: step.sheetIndex,
                  decoration: const InputDecoration(
                    labelText: 'Sheet',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var i = 0; i < sheets.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${sheets[i].name} (${sheets[i].rows.length} rows)',
                        ),
                      ),
                  ],
                  onChanged: (index) {
                    if (index != null) {
                      flow.selectSheet(index);
                    }
                  },
                ),
              ],
              const SizedBox(height: 20),
              if (sheet.isEmpty)
                Text(
                  'This sheet has no data rows. Choose another sheet or file.',
                  style: context.text.body.copyWith(
                    color: context.colors.warning,
                  ),
                )
              else ...[
                Text(
                  'Match each field to a column in your file. We guessed '
                  'from the column names — check them.',
                  style: context.text.bodyMuted,
                ),
                const SizedBox(height: 12),
                for (final field in LeadField.values)
                  _FieldMapping(
                    // Keyed by the column too: picking a column used by another field
                    // clears that field, and its dropdown must show it.
                    key: ValueKey(
                      '${step.sheetIndex}-${field.name}-${step.mapping[field]}',
                    ),
                    field: field,
                    sheet: sheet,
                    column: step.mapping[field],
                    onChanged: (column) => flow.setColumn(field, column),
                  ),
              ],
            ],
          ),
        ),
        _BottomBar(
          hint: step.mapping.isComplete
              ? null
              : 'Choose the Name and Phone columns to continue.',
          child: FilledButton(
            onPressed: step.mapping.isComplete && !sheet.isEmpty
                ? flow.review
                : null,
            child: const Text('Check rows'),
          ),
        ),
      ],
    );
  }
}

class _FieldMapping extends StatelessWidget {
  const _FieldMapping({
    required this.field,
    required this.sheet,
    required this.column,
    required this.onChanged,
    super.key,
  });

  final LeadField field;
  final ParsedSheet sheet;
  final int? column;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final samples = column == null
        ? const <String>[]
        : sheet.rows
              .map((row) => row.cell(column!))
              .where((value) => value.isNotEmpty)
              .take(3)
              .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int?>(
            initialValue: column,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: field.required ? '${field.label} *' : field.label,
              border: const OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(child: Text('— Not in this file —')),
              for (var i = 0; i < sheet.headers.length; i++)
                DropdownMenuItem<int?>(
                  value: i,
                  child: Text(
                    sheet.headers[i],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
          if (samples.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'e.g. ${samples.join(' · ')}',
                style: context.text.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child, this.hint});

  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hint != null) ...[
                Text(hint!, style: context.text.caption),
                const SizedBox(height: 8),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
