import 'package:flutter/foundation.dart';

/// Lead fields an import column can fill.
enum LeadField {
  name('Name', required: true),
  phone('Phone', required: true),
  company('Company'),
  email('Email'),
  website('Website'),
  source('Source'),
  notes('Notes');

  const LeadField(this.label, {this.required = false});

  final String label;
  final bool required;

  /// Header names recognised for this field, compared after lower-casing and
  /// removing spaces and punctuation ("Mobile No." → "mobileno").
  List<String> get aliases => switch (this) {
    LeadField.name => const [
      'name',
      'fullname',
      'contactname',
      'contactperson',
      'clientname',
      'leadname',
      'customername',
      'person',
    ],
    LeadField.phone => const [
      'phone',
      'mobile',
      'contact',
      'phonenumber',
      'mobilenumber',
      'contactnumber',
      'contactno',
      'mobileno',
      'phoneno',
      'number',
      'whatsapp',
      'whatsappnumber',
      'cell',
      'cellphone',
      'telephone',
      'tel',
    ],
    LeadField.company => const [
      'company',
      'companyname',
      'business',
      'businessname',
      'organisation',
      'organization',
      'firm',
      'brand',
    ],
    LeadField.email => const ['email', 'emailaddress', 'emailid', 'mail'],
    LeadField.website => const ['website', 'web', 'url', 'site', 'websiteurl'],
    LeadField.source => const ['source', 'leadsource', 'channel'],
    LeadField.notes => const [
      'notes',
      'note',
      'remarks',
      'remark',
      'comments',
      'comment',
      'description',
      'details',
    ],
  };

  /// Words that identify the field inside a longer header
  /// ("Primary Mobile" → phone). Only used when no exact alias matched.
  List<String> get keywords => switch (this) {
    LeadField.name => const ['name'],
    LeadField.phone => const ['phone', 'mobile', 'whatsapp'],
    LeadField.company => const ['company', 'business'],
    LeadField.email => const ['email'],
    LeadField.website => const ['website'],
    LeadField.source => const ['source'],
    LeadField.notes => const ['note', 'remark', 'comment'],
  };
}

String _normalizeHeader(String header) =>
    header.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

/// Which spreadsheet column (index) fills which lead field.
@immutable
class ColumnMapping {
  const ColumnMapping(this.columns);

  /// Guesses the mapping from header names. Each column is used once;
  /// exact alias matches win over keyword matches.
  factory ColumnMapping.guess(List<String> headers) {
    final normalized = headers.map(_normalizeHeader).toList();
    final columns = <LeadField, int>{};
    final used = <int>{};

    void assign(bool Function(LeadField field, String header) matches) {
      for (final field in LeadField.values) {
        if (columns.containsKey(field)) {
          continue;
        }
        for (var i = 0; i < normalized.length; i++) {
          if (!used.contains(i) && matches(field, normalized[i])) {
            columns[field] = i;
            used.add(i);
            break;
          }
        }
      }
    }

    assign((field, header) => field.aliases.contains(header));
    assign((field, header) => field.keywords.any(header.contains));
    return ColumnMapping(columns);
  }

  final Map<LeadField, int> columns;

  int? operator [](LeadField field) => columns[field];

  /// Name and phone are mapped.
  bool get isComplete => LeadField.values
      .where((field) => field.required)
      .every(columns.containsKey);

  /// Maps [field] to [column] (or unmaps with null). A column can fill only
  /// one field, so it is removed from any other field first.
  ColumnMapping withColumn(LeadField field, int? column) {
    final next = {
      for (final entry in columns.entries)
        if (entry.value != column) entry.key: entry.value,
    }..remove(field);
    if (column != null) {
      next[field] = column;
    }
    return ColumnMapping(next);
  }

  @override
  bool operator ==(Object other) =>
      other is ColumnMapping && mapEquals(other.columns, columns);

  @override
  int get hashCode => Object.hashAllUnordered(
    columns.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
