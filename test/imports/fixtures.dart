import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

Uint8List csvBytes(String text) => Uint8List.fromList(utf8.encode(text));

/// Builds a real .xlsx file. [sheets] maps sheet name → rows; cells may be
/// String, int, double, or null.
Uint8List xlsxBytes(Map<String, List<List<Object?>>> sheets) {
  final excel = Excel.createExcel();
  final defaultName = excel.getDefaultSheet()!;
  var first = true;
  for (final MapEntry(key: name, value: rows) in sheets.entries) {
    if (first) {
      excel.rename(defaultName, name);
      first = false;
    }
    for (final row in rows) {
      excel.appendRow(name, [
        for (final cell in row)
          switch (cell) {
            null => null,
            final int n => IntCellValue(n),
            final double d => DoubleCellValue(d),
            _ => TextCellValue('$cell'),
          },
      ]);
    }
  }
  return Uint8List.fromList(excel.encode()!);
}
