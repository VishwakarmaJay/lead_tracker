import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';
import 'package:lead_tracker/src/imports/data/import_preview.dart';
import 'package:lead_tracker/src/imports/data/spreadsheet.dart';

import 'fixtures.dart';

ImportPreview _analyze(
  String csv, {
  Map<String, List<String>> existing = const {},
}) {
  final sheet = parseSpreadsheet(
    csvBytes(csv),
    SpreadsheetFormat.csv,
  ).sheets.single;
  return analyzeImport(
    ImportRequest(
      sheet: sheet,
      mapping: ColumnMapping.guess(sheet.headers),
      countryCode: '+91',
      existingNamesByPhone: existing,
      fileName: 'leads.csv',
    ),
  );
}

void main() {
  test('decides each row and keeps the original phone text', () {
    final preview = _analyze(
      'Name,Phone,Company,Email,Source\n'
      'Asha,98765 43210,Pixel,asha@pixel.in,LinkedIn\n'
      ',91234 56789,,,\n'
      'No Phone,,,,\n'
      'Asha again,+91 98765-43210,,,\n'
      'Landline-ish,12345,,,\n'
      'Saved One,9000000001,,,\n'
      'Odd Email,9000000002,,asha@,\n',
      existing: {
        '+919000000001': ['Dev Mehta'],
      },
    );

    final outcomes = {
      for (final c in preview.candidates) c.rowNumber: c.outcome,
    };
    expect(outcomes, {
      2: RowOutcome.ready,
      3: RowOutcome.invalid,
      4: RowOutcome.invalid,
      5: RowOutcome.fileDuplicate,
      6: RowOutcome.unrecognisedPhone,
      7: RowOutcome.existingDuplicate,
      8: RowOutcome.ready,
    });

    final first = preview.candidates.first;
    expect(first.draft.phone, '98765 43210');
    expect(first.draft.phoneNormalized, '+919876543210');
    expect(first.draft.company, 'Pixel');
    expect(first.draft.source, 'LinkedIn');

    final byRow = {for (final c in preview.candidates) c.rowNumber: c};
    expect(byRow[3]!.reason, 'No name');
    expect(byRow[4]!.reason, 'No phone');
    expect(byRow[5]!.reason, 'Same number as row 2');
    expect(byRow[7]!.reason, 'Already saved as Dev Mehta');
    expect(byRow[8]!.warning, 'Email looks incomplete');
    // No source column value → the file name.
    expect(byRow[8]!.draft.source, 'Import: leads.csv');
  });

  test('options decide which rows are imported', () {
    final preview = _analyze(
      'Name,Phone\n'
      'Ready,9876543210\n'
      'Unknown,12345\n'
      'Saved,9000000001\n'
      'Repeat,98765 43210\n'
      'Bad,\n',
      existing: {
        '+919000000001': ['Dev'],
      },
    );

    List<String> names(ImportOptions options) =>
        preview.draftsToImport(options).map((d) => d.name).toList();

    expect(names(const ImportOptions()), ['Ready']);
    expect(names(const ImportOptions(includeUnrecognisedPhones: true)), [
      'Ready',
      'Unknown',
    ]);
    expect(
      names(
        const ImportOptions(
          includeUnrecognisedPhones: true,
          includeExistingDuplicates: true,
        ),
      ),
      ['Ready', 'Unknown', 'Saved'],
    );
  });

  test('unrecognised numbers repeated in the file are caught by digits', () {
    final preview = _analyze('Name,Phone\nA,12-345\nB,12 345\n');
    expect(preview.candidates.last.outcome, RowOutcome.fileDuplicate);
  });

  test('blank rows are reported', () {
    final preview = _analyze('Name,Phone\nA,9876543210\n\nB,9123456789\n');
    expect(preview.emptyRows, 1);
    expect(preview.count(RowOutcome.ready), 2);
  });
}
