import 'dart:isolate';

import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/instances/file_picker_service.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';
import 'package:lead_tracker/src/imports/data/import_preview.dart';
import 'package:lead_tracker/src/imports/data/spreadsheet.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:lead_tracker/src/settings/providers/settings_provider.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';
import 'package:lead_tracker/src/shared/providers/busy_operations_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'import_flow_provider.g.dart';

/// The import wizard's current step.
sealed class ImportState {
  const ImportState();
}

/// Waiting for the user to choose a file.
class ImportStart extends ImportState {
  const ImportStart({this.error});

  /// Why the last attempt failed (unsupported file, unreadable, …).
  final String? error;
}

/// Reading, analysing, or saving. [message] says which.
class ImportWorking extends ImportState {
  const ImportWorking(this.message);

  final String message;
}

/// Choose the sheet and which column fills which field.
class ImportMapping extends ImportState {
  const ImportMapping({
    required this.fileName,
    required this.workbook,
    required this.sheetIndex,
    required this.mapping,
  });

  final String fileName;
  final ParsedWorkbook workbook;
  final int sheetIndex;
  final ColumnMapping mapping;

  ParsedSheet get sheet => workbook.sheets[sheetIndex];
}

/// Counts, per-row outcomes, and the include options. Nothing saved yet.
class ImportReview extends ImportState {
  const ImportReview({
    required this.mappingStep,
    required this.preview,
    required this.options,
  });

  final ImportMapping mappingStep;
  final ImportPreview preview;
  final ImportOptions options;

  int get importCount => preview.draftsToImport(options).length;
}

class ImportDone extends ImportState {
  const ImportDone({required this.imported, required this.skipped});

  final int imported;
  final int skipped;
}

/// Runs the XLSX/CSV import. Nothing is written until [confirmImport], which
/// inserts every selected row in one transaction — so leaving the screen at
/// any earlier step, or a failure while saving, leaves the database as it was.
@riverpod
class ImportFlow extends _$ImportFlow {
  @override
  ImportState build() => const ImportStart();

  Future<void> pickFile() async {
    final PickedFile? file;
    try {
      file = await ref.read(filePickerServiceProvider).pickSpreadsheet();
    } on AppException catch (e) {
      state = ImportStart(error: e.message);
      return;
    } on Exception {
      state = const ImportStart(error: 'The file picker could not open.');
      return;
    }
    if (file == null) {
      return; // Cancelled.
    }
    await openFile(file);
  }

  /// Parses a picked file (also the entry point for tests).
  Future<void> openFile(PickedFile file) async {
    final format = SpreadsheetFormat.fromFileName(file.name);
    if (format == null) {
      state = const ImportStart(
        error: 'Choose an Excel (.xlsx) or CSV (.csv) file.',
      );
      return;
    }
    state = const ImportWorking('Reading file…');
    try {
      final bytes = file.bytes;
      final workbook = await Isolate.run(
        () => parseSpreadsheet(bytes, format),
      ).guard();
      if (!ref.mounted) {
        return;
      }
      final index = workbook.defaultSheetIndex;
      state = ImportMapping(
        fileName: file.name,
        workbook: workbook,
        sheetIndex: index,
        mapping: ColumnMapping.guess(workbook.sheets[index].headers),
      );
    } on AppException catch (e) {
      if (ref.mounted) {
        state = ImportStart(
          error: e.type == ErrorType.parse
              ? 'This file could not be read as a spreadsheet.'
              : e.message,
        );
      }
    }
  }

  void selectSheet(int index) {
    final current = state;
    if (current is ImportMapping && index != current.sheetIndex) {
      state = ImportMapping(
        fileName: current.fileName,
        workbook: current.workbook,
        sheetIndex: index,
        mapping: ColumnMapping.guess(current.workbook.sheets[index].headers),
      );
    }
  }

  void setColumn(LeadField field, int? column) {
    final current = state;
    if (current is ImportMapping) {
      state = ImportMapping(
        fileName: current.fileName,
        workbook: current.workbook,
        sheetIndex: current.sheetIndex,
        mapping: current.mapping.withColumn(field, column),
      );
    }
  }

  /// Analyses every row against the mapping and the saved leads.
  Future<void> review() async {
    final current = state;
    if (current is! ImportMapping || !current.mapping.isComplete) {
      return;
    }
    state = const ImportWorking('Checking rows…');
    try {
      final existing = await ref
          .read(leadRepositoryProvider)
          .activeNamesByNormalizedPhone();
      final countryCode =
          ref.read(settingsProvider).value?.defaultCountryCallingCode ?? '+91';
      final request = ImportRequest(
        sheet: current.sheet,
        mapping: current.mapping,
        countryCode: countryCode,
        existingNamesByPhone: existing,
        fileName: current.fileName,
      );
      final preview = await Isolate.run(() => analyzeImport(request)).guard();
      if (ref.mounted) {
        state = ImportReview(
          mappingStep: current,
          preview: preview,
          options: const ImportOptions(),
        );
      }
    } on AppException catch (e) {
      if (ref.mounted) {
        state = current;
        _report(e);
      }
    }
  }

  void backToMapping() {
    final current = state;
    if (current is ImportReview) {
      state = current.mappingStep;
    }
  }

  void setOptions(ImportOptions options) {
    final current = state;
    if (current is ImportReview) {
      state = ImportReview(
        mappingStep: current.mappingStep,
        preview: current.preview,
        options: options,
      );
    }
  }

  /// Saves the selected rows in one transaction (all or nothing).
  Future<void> confirmImport() async {
    final current = state;
    if (current is! ImportReview) {
      return;
    }
    final drafts = current.preview.draftsToImport(current.options);
    if (drafts.isEmpty) {
      return;
    }
    state = ImportWorking('Importing ${drafts.length} leads…');
    try {
      await ref
          .read(busyOperationsProvider.notifier)
          .track(() => ref.read(leadRepositoryProvider).createLeads(drafts));
      ref.refreshLeadViews();
      if (ref.mounted) {
        state = ImportDone(
          imported: drafts.length,
          skipped: current.preview.candidates.length - drafts.length,
        );
      }
    } on AppException catch (e) {
      if (ref.mounted) {
        // Nothing was saved; go back so the user can retry.
        state = current;
        _report(e);
      }
    }
  }

  void restart() => state = const ImportStart();

  /// Errors after the first step keep the user on their step and show a
  /// snack bar; nothing has been saved.
  void _report(AppException error) => error.message.showSnackBar();
}
