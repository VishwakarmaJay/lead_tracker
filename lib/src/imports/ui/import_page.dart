import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/imports/providers/import_flow_provider.dart';
import 'package:lead_tracker/src/imports/ui/sections/import_done_section.dart';
import 'package:lead_tracker/src/imports/ui/sections/import_mapping_section.dart';
import 'package:lead_tracker/src/imports/ui/sections/import_review_section.dart';
import 'package:lead_tracker/src/imports/ui/sections/import_start_section.dart';

/// XLSX / CSV import wizard: choose file → map columns → review → done.
/// Nothing is saved before "Import" on the review step.
@RoutePage()
class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importFlowProvider);
    final flow = ref.read(importFlowProvider.notifier);

    // Back steps through the wizard instead of leaving it.
    final canLeave = state is ImportStart || state is ImportDone;

    return PopScope(
      canPop: canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        switch (state) {
          case ImportReview():
            flow.backToMapping();
          case ImportMapping():
            flow.restart();
          case ImportStart() || ImportDone() || ImportWorking():
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_title(state))),
        body: switch (state) {
          ImportStart(:final error) => ImportStartSection(error: error),
          ImportWorking(:final message) => _Working(message),
          ImportMapping() => ImportMappingSection(step: state),
          ImportReview() => ImportReviewSection(step: state),
          ImportDone() => ImportDoneSection(result: state),
        },
      ),
    );
  }

  static String _title(ImportState state) => switch (state) {
    ImportStart() || ImportWorking() => 'Import leads',
    ImportMapping() => 'Match columns',
    ImportReview() => 'Review import',
    ImportDone() => 'Import finished',
  };
}

class _Working extends StatelessWidget {
  const _Working(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: context.text.body),
        ],
      ),
    );
  }
}
