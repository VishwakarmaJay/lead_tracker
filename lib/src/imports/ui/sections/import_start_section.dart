import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/imports/providers/import_flow_provider.dart';

class ImportStartSection extends ConsumerWidget {
  const ImportStartSection({this.error, super.key});

  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.upload_file, size: 56, color: context.colors.primary),
        const SizedBox(height: 16),
        Text(
          'Import from Excel or CSV',
          style: context.text.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your file should have:', style: context.text.label),
                const SizedBox(height: 8),
                const _Point('Column names in the first row.'),
                const _Point('A name and a phone column (required).'),
                const _Point(
                  'Optional: company, email, website, source, notes.',
                ),
                const _Point(
                  "You'll match the columns and check every row before "
                  'anything is saved.',
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.error_outline, color: context.colors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error!,
                  style: context.text.body.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => ref.read(importFlowProvider.notifier).pickFile(),
          icon: const Icon(Icons.folder_open),
          label: const Text('Choose file'),
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: context.text.body),
          Expanded(child: Text(text, style: context.text.body)),
        ],
      ),
    );
  }
}
