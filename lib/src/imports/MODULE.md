# imports

**Path:** `lib/src/imports/` · **Layer:** feature · **Status:** Milestone 3 done

XLSX / CSV lead import. Nothing is saved until the user confirms on the review step, and then every selected row is inserted in **one transaction**.

## Flow

`ImportRoute` (`ui/import_page.dart`) shows the step for the current `ImportState`:

| State | Section | What |
| --- | --- | --- |
| `ImportStart(error?)` | `import_start_section.dart` | What the file needs; **Choose file**; last error |
| `ImportWorking(message)` | (in page) | Reading / checking / importing |
| `ImportMapping` | `import_mapping_section.dart` | Sheet picker (XLSX), a dropdown per field with sample values; **Check rows** once Name and Phone are mapped |
| `ImportReview` | `import_review_section.dart` | Counts per outcome, include switches, every row with reason; **Import N leads** |
| `ImportDone` | `import_done_section.dart` | Imported / skipped; View leads; Import another file |

System back steps back (review → mapping → start) instead of leaving mid-way.

## Providers

`importFlowProvider` (`ImportFlow`): `pickFile`, `openFile(PickedFile)`, `selectSheet`, `setColumn`, `review`, `backToMapping`, `setOptions`, `confirmImport`, `restart`. Parsing and analysis run in `Isolate.run`. Errors after the first step show a snack bar and keep the user on their step.

## Data (pure Dart, no Flutter widgets)

- `data/spreadsheet.dart` — `parseSpreadsheet(bytes, format)` → `ParsedWorkbook` / `ParsedSheet` / `SheetRow` (1-based row numbers).
- `data/column_mapping.dart` — `LeadField` (aliases, keywords), `ColumnMapping.guess`, `withColumn`.
- `data/import_preview.dart` — `analyzeImport(ImportRequest)` → `ImportPreview`; `RowOutcome`; `ImportOptions`; `draftsToImport(options)`.

## Rules

- Rows missing a name or phone, and repeats of a number earlier in the file, are always skipped.
- Unrecognised numbers and numbers already saved are skipped by default; switches include them. Already-saved numbers become **new** leads; saved leads are never modified.
- Source defaults to `Import: <file name>`.
- The insert is tracked by `busyOperationsProvider`, so **Restart now** waits for it.

## Depends on

`core/instances/file_picker_service.dart`, `leads` (repository, validators, `refreshLeadViews`), `settings` (default country code).

## Tests

`test/imports/` — parser (CSV and real XLSX files), mapping, analysis, the whole flow against a test database (including a forced failure mid-insert that leaves nothing saved), and the review screen.
