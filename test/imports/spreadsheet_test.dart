import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/imports/data/spreadsheet.dart';

import 'fixtures.dart';

void main() {
  test('format comes from the file extension', () {
    expect(
      SpreadsheetFormat.fromFileName('Leads.XLSX'),
      SpreadsheetFormat.xlsx,
    );
    expect(SpreadsheetFormat.fromFileName('a.csv'), SpreadsheetFormat.csv);
    expect(SpreadsheetFormat.fromFileName('old.xls'), isNull);
    expect(SpreadsheetFormat.fromFileName('notes.txt'), isNull);
  });

  group('CSV', () {
    ParsedSheet parse(String text) =>
        parseSpreadsheet(csvBytes(text), SpreadsheetFormat.csv).sheets.single;

    test('reads headers and rows, trimming cells', () {
      final sheet = parse(
        'Name, Phone \nAsha , 98765 43210\nBharat,91234 56789\n',
      );
      expect(sheet.headers, ['Name', 'Phone']);
      expect(sheet.rows.map((r) => r.cells), [
        ['Asha', '98765 43210'],
        ['Bharat', '91234 56789'],
      ]);
      expect(sheet.rows.map((r) => r.rowNumber), [2, 3]);
    });

    test('detects semicolon and tab separators', () {
      expect(parse('Name;Phone\nAsha;1\n').rows.single.cells, ['Asha', '1']);
      expect(parse('Name\tPhone\nAsha\t1\n').rows.single.cells, ['Asha', '1']);
    });

    test('handles quotes, commas and line breaks inside cells', () {
      final sheet = parse(
        'Name,Notes\n"Rao, Asha","Line one\nline two"\n"Say ""hi""",x\n',
      );
      expect(sheet.rows[0].cells, ['Rao, Asha', 'Line one\nline two']);
      expect(sheet.rows[1].cells, ['Say "hi"', 'x']);
    });

    test('strips the UTF-8 BOM Excel adds', () {
      expect(parse('﻿Name,Phone\nA,1\n').headers.first, 'Name');
    });

    test('falls back to Latin-1 for non-UTF-8 files', () {
      final bytes = Uint8List.fromList(latin1.encode('Name,Phone\nJosé,1\n'));
      final sheet = parseSpreadsheet(
        bytes,
        SpreadsheetFormat.csv,
      ).sheets.single;
      expect(sheet.rows.single.cells.first, 'José');
    });

    test('skips leading blank lines, keeps real row numbers, counts gaps', () {
      final sheet = parse('\n\nName,Phone\nA,1\n\n,\nB,2\n\n\n');
      expect(sheet.headers, ['Name', 'Phone']);
      expect(sheet.rows.map((r) => r.rowNumber), [4, 7]);
      expect(sheet.emptyRows, 2);
    });

    test('names blank headers and pads short rows', () {
      final sheet = parse('Name,,Phone\nA,x,1,extra\nB\n');
      expect(sheet.headers, ['Name', 'Column 2', 'Phone', 'Column 4']);
      expect(sheet.rows[0].cells, ['A', 'x', '1', 'extra']);
      expect(sheet.rows[1].cells, ['B', '', '', '']);
      expect(sheet.rows[1].cell(10), '');
    });

    test('an empty file is a format error', () {
      expect(
        () => parseSpreadsheet(csvBytes('\n \n'), SpreadsheetFormat.csv),
        throwsFormatException,
      );
    });
  });

  group('XLSX', () {
    test('reads text and numeric cells; whole numbers lose ".0"', () {
      final bytes = xlsxBytes({
        'Leads': [
          ['Name', 'Phone', 'Budget'],
          ['Asha', 9876543210, 1500.5],
          ['Bharat', 9123456789.0, null],
        ],
      });
      final sheet = parseSpreadsheet(
        bytes,
        SpreadsheetFormat.xlsx,
      ).sheets.single;
      expect(sheet.name, 'Leads');
      expect(sheet.headers, ['Name', 'Phone', 'Budget']);
      expect(sheet.rows[0].cells, ['Asha', '9876543210', '1500.5']);
      expect(sheet.rows[1].cells, ['Bharat', '9123456789', '']);
    });

    test('keeps every sheet and defaults to the first one with data', () {
      final bytes = xlsxBytes({
        'Cover': [
          ['Leads export'],
        ],
        'Data': [
          ['Name', 'Phone'],
          ['Asha', '1'],
        ],
      });
      final workbook = parseSpreadsheet(bytes, SpreadsheetFormat.xlsx);
      expect(workbook.sheets.map((s) => s.name), ['Cover', 'Data']);
      expect(workbook.defaultSheetIndex, 1);
    });

    test('a corrupt file is a format error', () {
      expect(
        () => parseSpreadsheet(
          csvBytes('not a zip file'),
          SpreadsheetFormat.xlsx,
        ),
        throwsFormatException,
      );
    });
  });
}
