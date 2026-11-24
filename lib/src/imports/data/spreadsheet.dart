import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

enum SpreadsheetFormat {
  csv,
  xlsx;

  /// From the file name's extension; null when unsupported.
  static SpreadsheetFormat? fromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) {
      return SpreadsheetFormat.csv;
    }
    if (lower.endsWith('.xlsx')) {
      return SpreadsheetFormat.xlsx;
    }
    return null;
  }
}

/// One data row, with its row number as shown in the spreadsheet (1-based),
/// so problems can be reported as "row 14".
@immutable
class SheetRow {
  const SheetRow({required this.rowNumber, required this.cells});

  final int rowNumber;

  /// Trimmed text, one entry per header column.
  final List<String> cells;

  String cell(int column) => column < cells.length ? cells[column] : '';
}

@immutable
class ParsedSheet {
  const ParsedSheet({
    required this.name,
    required this.headers,
    required this.rows,
    required this.emptyRows,
  });

  final String name;

  /// The first non-empty row. Blank header cells become "Column N".
  final List<String> headers;
  final List<SheetRow> rows;

  /// Blank rows between data rows (skipped).
  final int emptyRows;

  bool get isEmpty => rows.isEmpty;
}

@immutable
class ParsedWorkbook {
  const ParsedWorkbook(this.sheets);

  /// CSV files have exactly one sheet.
  final List<ParsedSheet> sheets;

  /// The first sheet that has data, else the first sheet.
  int get defaultSheetIndex {
    final index = sheets.indexWhere((sheet) => !sheet.isEmpty);
    return index < 0 ? 0 : index;
  }
}

/// Parses a CSV or XLSX file. Pure Dart, so it can run in a background
/// isolate. Throws [FormatException] for unreadable or empty files.
ParsedWorkbook parseSpreadsheet(Uint8List bytes, SpreadsheetFormat format) {
  final workbook = switch (format) {
    SpreadsheetFormat.csv => _parseCsv(bytes),
    SpreadsheetFormat.xlsx => _parseXlsx(bytes),
  };
  if (workbook.sheets.isEmpty ||
      workbook.sheets.every((sheet) => sheet.headers.isEmpty)) {
    throw const FormatException('The file has no rows.');
  }
  return workbook;
}

ParsedWorkbook _parseCsv(Uint8List bytes) {
  String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    // Older Excel "CSV" exports are often Windows-1252 / Latin-1.
    text = latin1.decode(bytes);
  }
  if (text.startsWith('﻿')) {
    text = text.substring(1);
  }
  // Keep blank lines so row numbers match what the user sees.
  final rows = Csv(skipEmptyLines: false).decode(text);
  return ParsedWorkbook([
    _buildSheet('CSV', [
      for (final row in rows) [for (final cell in row) '${cell ?? ''}'],
    ]),
  ]);
}

ParsedWorkbook _parseXlsx(Uint8List bytes) {
  final Excel excel;
  try {
    excel = Excel.decodeBytes(bytes);
  } on Object {
    // The package throws assorted errors for corrupt or non-xlsx files.
    throw const FormatException('This is not a readable .xlsx file.');
  }
  return ParsedWorkbook([
    for (final entry in excel.tables.entries)
      _buildSheet(entry.key, [
        for (final row in entry.value.rows)
          [for (final cell in row) _cellText(cell?.value)],
      ]),
  ]);
}

String _cellText(CellValue? value) {
  return switch (value) {
    null => '',
    TextCellValue() => value.value.toString(),
    IntCellValue(:final value) => '$value',
    // Phone numbers typed into Excel become numbers: 9876543210.0.
    DoubleCellValue(:final value) =>
      value == value.truncateToDouble() && value.abs() < 1e15
          ? value.toInt().toString()
          : '$value',
    BoolCellValue(:final value) => '$value',
    DateCellValue(:final year, :final month, :final day) =>
      '$year-${_two(month)}-${_two(day)}',
    // Only the formula is stored, not its result; treat as empty.
    FormulaCellValue() => '',
    _ => value.toString(),
  };
}

String _two(int n) => n.toString().padLeft(2, '0');

ParsedSheet _buildSheet(String name, List<List<String>> rawRows) {
  final rows = [
    for (final row in rawRows) [for (final cell in row) cell.trim()],
  ];
  bool blank(List<String> row) => row.every((cell) => cell.isEmpty);

  final headerIndex = rows.indexWhere((row) => !blank(row));
  if (headerIndex < 0) {
    return ParsedSheet(
      name: name,
      headers: const [],
      rows: const [],
      emptyRows: 0,
    );
  }

  final headerRow = rows[headerIndex];
  // Width = the widest row, so data under a blank header isn't lost.
  final width = rows.fold<int>(
    headerRow.length,
    (max, row) => row.length > max ? row.length : max,
  );
  final headers = [
    for (var i = 0; i < width; i++)
      i < headerRow.length && headerRow[i].isNotEmpty
          ? headerRow[i]
          : 'Column ${i + 1}',
  ];

  // Only blank rows between data rows count; trailing blanks are ignored.
  final lastIndex = rows.lastIndexWhere((row) => !blank(row));
  final data = <SheetRow>[];
  var emptyRows = 0;
  for (var i = headerIndex + 1; i <= lastIndex; i++) {
    final row = rows[i];
    if (blank(row)) {
      emptyRows++;
      continue;
    }
    data.add(
      SheetRow(
        rowNumber: i + 1,
        cells: [for (var c = 0; c < width; c++) c < row.length ? row[c] : ''],
      ),
    );
  }
  return ParsedSheet(
    name: name,
    headers: headers,
    rows: data,
    emptyRows: emptyRows,
  );
}
