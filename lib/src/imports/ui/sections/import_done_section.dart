import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/imports/providers/import_flow_provider.dart';

class ImportDoneSection extends ConsumerWidget {
  const ImportDoneSection({required this.result, super.key});

  final ImportDone result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imported = result.imported;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: context.colors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Imported $imported ${imported == 1 ? 'lead' : 'leads'}',
              style: context.text.title,
            ),
            if (result.skipped > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${result.skipped} '
                '${result.skipped == 1 ? 'row was' : 'rows were'} skipped.',
                style: context.text.bodyMuted,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.router.maybePop(),
              child: const Text('View leads'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(importFlowProvider.notifier).restart(),
              child: const Text('Import another file'),
            ),
          ],
        ),
      ),
    );
  }
}
