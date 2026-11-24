import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';
import 'package:lead_tracker/src/imports/data/import_preview.dart';
import 'package:lead_tracker/src/imports/data/spreadsheet.dart';
import 'package:lead_tracker/src/imports/providers/import_flow_provider.dart';
import 'package:lead_tracker/src/imports/ui/sections/import_review_section.dart';
import 'package:lead_tracker/src/theme/app_theme.dart';

import 'fixtures.dart';

void main() {
  testWidgets('review shows counts, choices, and the import button', (
    tester,
  ) async {
    final workbook = parseSpreadsheet(
      csvBytes(
        'Name,Phone\nAsha,9876543210\nUnknown,12345\nSaved,9000000001\n,1\n',
      ),
      SpreadsheetFormat.csv,
    );
    final sheet = workbook.sheets.single;
    final mapping = ColumnMapping.guess(sheet.headers);
    final step = ImportReview(
      mappingStep: ImportMapping(
        fileName: 'x.csv',
        workbook: workbook,
        sheetIndex: 0,
        mapping: mapping,
      ),
      preview: analyzeImport(
        ImportRequest(
          sheet: sheet,
          mapping: mapping,
          countryCode: '+91',
          existingNamesByPhone: const {
            '+919000000001': ['Dev'],
          },
          fileName: 'x.csv',
        ),
      ),
      options: const ImportOptions(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(body: ImportReviewSection(step: step)),
        ),
      ),
    );

    expect(find.text('Ready to import'), findsOneWidget);
    expect(find.text("Number can't be recognised"), findsOneWidget);
    expect(find.text('Number already saved'), findsOneWidget);
    expect(find.text('Missing name or phone (skipped)'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(2));
    expect(find.text('Import 1 lead'), findsOneWidget);
    expect(find.textContaining('Already saved as Dev'), findsOneWidget);
  });
}
