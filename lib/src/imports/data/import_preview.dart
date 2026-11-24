import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/utils/phone_normalizer.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';
import 'package:lead_tracker/src/imports/data/spreadsheet.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_form_provider.dart';

/// What happens to one spreadsheet row.
enum RowOutcome {
  /// Will be imported.
  ready,

  /// Phone can't be normalised. Skipped unless the user includes them.
  unrecognisedPhone,

  /// Number already belongs to a saved lead. Skipped unless the user
  /// includes them (a new lead is created; the saved one is never changed).
  existingDuplicate,

  /// Same number as an earlier row in this file. Always skipped.
  fileDuplicate,

  /// Missing name or phone. Always skipped.
  invalid,
}

@immutable
class ImportCandidate {
  const ImportCandidate({
    required this.rowNumber,
    required this.draft,
    required this.outcome,
    this.reason,
    this.warning,
  });

  /// Row number in the spreadsheet (1-based, header included).
  final int rowNumber;
  final LeadDraft draft;
  final RowOutcome outcome;

  /// Why the row is skipped (or needs a decision).
  final String? reason;

  /// Imported anyway, but worth a look (e.g. an odd email).
  final String? warning;
}

/// The user's choices on the review screen. Defaults are the safe ones.
@immutable
class ImportOptions {
  const ImportOptions({
    this.includeUnrecognisedPhones = false,
    this.includeExistingDuplicates = false,
  });

  final bool includeUnrecognisedPhones;
  final bool includeExistingDuplicates;

  ImportOptions copyWith({
    bool? includeUnrecognisedPhones,
    bool? includeExistingDuplicates,
  }) {
    return ImportOptions(
      includeUnrecognisedPhones:
          includeUnrecognisedPhones ?? this.includeUnrecognisedPhones,
      includeExistingDuplicates:
          includeExistingDuplicates ?? this.includeExistingDuplicates,
    );
  }
}

@immutable
class ImportPreview {
  const ImportPreview({required this.candidates, required this.emptyRows});

  final List<ImportCandidate> candidates;

  /// Blank rows in the sheet (skipped).
  final int emptyRows;

  int count(RowOutcome outcome) =>
      candidates.where((c) => c.outcome == outcome).length;

  bool isIncluded(ImportCandidate candidate, ImportOptions options) =>
      switch (candidate.outcome) {
        RowOutcome.ready => true,
        RowOutcome.unrecognisedPhone => options.includeUnrecognisedPhones,
        RowOutcome.existingDuplicate => options.includeExistingDuplicates,
        RowOutcome.fileDuplicate || RowOutcome.invalid => false,
      };

  List<LeadDraft> draftsToImport(ImportOptions options) => [
    for (final candidate in candidates)
      if (isIncluded(candidate, options)) candidate.draft,
  ];
}

/// Everything [analyzeImport] needs; plain data so it can cross isolates.
@immutable
class ImportRequest {
  const ImportRequest({
    required this.sheet,
    required this.mapping,
    required this.countryCode,
    required this.existingNamesByPhone,
    required this.fileName,
  });

  final ParsedSheet sheet;
  final ColumnMapping mapping;

  /// Default country code for phone normalisation, e.g. `+91`.
  final String countryCode;

  /// Normalised phone → names of active leads with that number.
  final Map<String, List<String>> existingNamesByPhone;

  /// Used as the lead's source when the file has no source column.
  final String fileName;
}

/// Turns sheet rows into lead drafts and decides each row's outcome.
/// Pure: nothing is written.
ImportPreview analyzeImport(ImportRequest request) {
  final normalizer = PhoneNormalizer(defaultCountryCode: request.countryCode);
  final mapping = request.mapping;
  final defaultSource = 'Import: ${request.fileName}';
  final firstRowByPhone = <String, int>{};
  final candidates = <ImportCandidate>[];

  String text(SheetRow row, LeadField field) {
    final column = mapping[field];
    return column == null ? '' : row.cell(column).trim();
  }

  String? optional(SheetRow row, LeadField field) {
    final value = text(row, field);
    return value.isEmpty ? null : value;
  }

  for (final row in request.sheet.rows) {
    final name = text(row, LeadField.name);
    final phone = text(row, LeadField.phone);
    final normalized = normalizer.normalize(phone);
    final email = optional(row, LeadField.email);

    final draft = LeadDraft(
      name: name,
      phone: phone,
      phoneNormalized: normalized,
      company: optional(row, LeadField.company),
      email: email,
      website: optional(row, LeadField.website),
      source: optional(row, LeadField.source) ?? defaultSource,
      notes: optional(row, LeadField.notes),
    );

    ImportCandidate candidateWith(RowOutcome outcome, [String? reason]) =>
        ImportCandidate(
          rowNumber: row.rowNumber,
          draft: draft,
          outcome: outcome,
          reason: reason,
          warning: validateLeadEmail(email) == null
              ? null
              : 'Email looks incomplete',
        );

    final nameError = validateLeadName(name);
    final phoneError = validateLeadPhone(phone);
    if (nameError != null || phoneError != null) {
      final reasons = [
        if (nameError != null) name.isEmpty ? 'No name' : 'Name too long',
        if (phoneError != null)
          phone.isEmpty ? 'No phone' : 'Phone has no digits',
      ];
      candidates.add(candidateWith(RowOutcome.invalid, reasons.join(', ')));
      continue;
    }

    // Unrecognised numbers are compared by their digits only.
    final key = normalized ?? phone.replaceAll(RegExp(r'\D'), '');
    final earlierRow = firstRowByPhone[key];
    if (earlierRow != null) {
      candidates.add(
        candidateWith(
          RowOutcome.fileDuplicate,
          'Same number as row $earlierRow',
        ),
      );
      continue;
    }
    firstRowByPhone[key] = row.rowNumber;

    if (normalized == null) {
      candidates.add(
        candidateWith(
          RowOutcome.unrecognisedPhone,
          "Can't recognise the number",
        ),
      );
      continue;
    }

    final existing = request.existingNamesByPhone[normalized];
    if (existing != null && existing.isNotEmpty) {
      candidates.add(
        candidateWith(
          RowOutcome.existingDuplicate,
          'Already saved as ${existing.take(2).join(', ')}',
        ),
      );
      continue;
    }

    candidates.add(candidateWith(RowOutcome.ready));
  }

  return ImportPreview(
    candidates: candidates,
    emptyRows: request.sheet.emptyRows,
  );
}
