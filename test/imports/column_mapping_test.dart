import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';

void main() {
  test('guesses common header names', () {
    final mapping = ColumnMapping.guess(const [
      'S.No',
      'Full Name',
      'Mobile No.',
      'Company Name',
      'E-mail',
      'Website',
      'Lead Source',
      'Remarks',
    ]);
    expect(mapping[LeadField.name], 1);
    expect(mapping[LeadField.phone], 2);
    expect(mapping[LeadField.company], 3);
    expect(mapping[LeadField.email], 4);
    expect(mapping[LeadField.website], 5);
    expect(mapping[LeadField.source], 6);
    expect(mapping[LeadField.notes], 7);
    expect(mapping.isComplete, isTrue);
  });

  test('falls back to keywords inside longer headers', () {
    final mapping = ColumnMapping.guess(const [
      'Client',
      'Primary Mobile',
      'Owner name',
    ]);
    expect(mapping[LeadField.phone], 1);
    expect(mapping[LeadField.name], 2);
  });

  test('exact matches win, and each column is used once', () {
    final mapping = ColumnMapping.guess(const [
      'Company Name',
      'Name',
      'Phone',
    ]);
    expect(mapping[LeadField.company], 0);
    expect(mapping[LeadField.name], 1);
  });

  test('incomplete without name or phone', () {
    final mapping = ColumnMapping.guess(const ['Company', 'City']);
    expect(mapping.isComplete, isFalse);
  });

  test('choosing a column moves it from any other field', () {
    final mapping = ColumnMapping.guess(const ['Name', 'Phone', 'Company']);
    final moved = mapping.withColumn(LeadField.notes, 2);
    expect(moved[LeadField.notes], 2);
    expect(moved[LeadField.company], isNull);

    final cleared = moved.withColumn(LeadField.phone, null);
    expect(cleared[LeadField.phone], isNull);
    expect(cleared.isComplete, isFalse);
    expect(mapping, ColumnMapping.guess(const ['Name', 'Phone', 'Company']));
  });
}
