import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';
import 'package:lead_tracker/src/imports/data/import_preview.dart';
import 'package:lead_tracker/src/imports/data/spreadsheet.dart';

/// docs/samples/leads_sample.csv backs DEVICE_TEST_CHECKLIST.md §H; keep the
/// numbers there in sync with these.
void main() {
  test('sample CSV gives the counts the device checklist expects', () {
    final bytes = Uint8List.fromList(
      File('docs/samples/leads_sample.csv').readAsBytesSync(),
    );
    final sheet = parseSpreadsheet(bytes, SpreadsheetFormat.csv).sheets.single;
    final mapping = ColumnMapping.guess(sheet.headers);
    expect(mapping[LeadField.name], 0);
    expect(mapping[LeadField.phone], 1);
    expect(mapping[LeadField.company], 2);
    expect(mapping[LeadField.email], 3);
    expect(mapping[LeadField.source], 4);
    expect(mapping[LeadField.notes], 5);

    final preview = analyzeImport(
      ImportRequest(
        sheet: sheet,
        mapping: mapping,
        countryCode: '+91',
        existingNamesByPhone: const {},
        fileName: 'leads_sample.csv',
      ),
    );
    expect(preview.count(RowOutcome.ready), 8);
    expect(preview.count(RowOutcome.unrecognisedPhone), 1);
    expect(preview.count(RowOutcome.fileDuplicate), 1);
    expect(preview.count(RowOutcome.invalid), 2);
    expect(preview.emptyRows, 1);
    final imported = preview.draftsToImport(const ImportOptions()).length;
    expect(preview.candidates.length - imported, 4); // "4 rows were skipped"
  });
}
