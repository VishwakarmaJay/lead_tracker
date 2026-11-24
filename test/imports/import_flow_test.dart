import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/file_picker_service.dart';
import 'package:lead_tracker/src/imports/data/column_mapping.dart';
import 'package:lead_tracker/src/imports/data/import_preview.dart';
import 'package:lead_tracker/src/imports/providers/import_flow_provider.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';

import '../helpers/test_container.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const csv =
      'Full Name,Mobile,Company\n'
      'Asha Rao,98765 43210,Pixel\n'
      'Bharat,91234 56789,\n'
      'Saved Already,90000 00001,\n'
      ',90000 00002,\n';

  Future<List<Lead>> allLeads(LeadRepository repo) =>
      repo.searchLeads(const LeadQuery());

  test('CSV: open → mapping → review → import', () async {
    final (container, db) = await createTestContainer();
    final repo = LeadRepository(db);
    await repo.createLead(
      const LeadDraft(
        name: 'Dev',
        phone: '9000000001',
        phoneNormalized: '+919000000001',
      ),
    );
    container.listen(importFlowProvider, (_, _) {});
    final flow = container.read(importFlowProvider.notifier);

    await flow.openFile(PickedFile(name: 'leads.csv', bytes: csvBytes(csv)));
    final mapping = container.read(importFlowProvider);
    expect(mapping, isA<ImportMapping>());
    mapping as ImportMapping;
    expect(mapping.mapping[LeadField.name], 0);
    expect(mapping.mapping[LeadField.phone], 1);

    await flow.review();
    final review = container.read(importFlowProvider) as ImportReview;
    expect(review.preview.count(RowOutcome.ready), 2);
    expect(review.preview.count(RowOutcome.existingDuplicate), 1);
    expect(review.preview.count(RowOutcome.invalid), 1);
    expect(review.importCount, 2);

    // Nothing is written before confirming.
    expect(await allLeads(repo), hasLength(1));

    await flow.confirmImport();
    final done = container.read(importFlowProvider) as ImportDone;
    expect(done.imported, 2);
    expect(done.skipped, 2);

    final names = (await allLeads(repo)).map((l) => l.name);
    expect(names, containsAll(['Asha Rao', 'Bharat', 'Dev']));
    final asha = (await allLeads(repo)).firstWhere((l) => l.name == 'Asha Rao');
    expect(asha.phoneNormalized, '+919876543210');
    expect(asha.company, 'Pixel');
    expect(asha.source, 'Import: leads.csv');
  });

  test('XLSX: picks the sheet with data and imports numeric phones', () async {
    final (container, db) = await createTestContainer();
    container.listen(importFlowProvider, (_, _) {});
    final flow = container.read(importFlowProvider.notifier);

    await flow.openFile(
      PickedFile(
        name: 'Prospects.xlsx',
        bytes: xlsxBytes({
          'Notes': [
            ['Exported 24 Nov'],
          ],
          'Prospects': [
            ['Name', 'Phone', 'Email'],
            ['Asha', 9876543210, 'asha@pixel.in'],
            ['Bharat', 9123456789.0, null],
          ],
        }),
      ),
    );
    final mapping = container.read(importFlowProvider) as ImportMapping;
    expect(mapping.sheet.name, 'Prospects');

    await flow.review();
    await flow.confirmImport();
    expect((container.read(importFlowProvider) as ImportDone).imported, 2);

    final leads = await LeadRepository(db).searchLeads(const LeadQuery());
    expect(leads.map((l) => l.phoneNormalized), [
      '+919876543210',
      '+919123456789',
    ]);
  });

  test('include options change what is saved', () async {
    final (container, db) = await createTestContainer();
    container.listen(importFlowProvider, (_, _) {});
    final flow = container.read(importFlowProvider.notifier);

    await flow.openFile(
      PickedFile(
        name: 'x.csv',
        bytes: csvBytes('Name,Phone\nA,9876543210\nB,12345\n'),
      ),
    );
    await flow.review();
    flow.setOptions(const ImportOptions(includeUnrecognisedPhones: true));
    await flow.confirmImport();

    final leads = await LeadRepository(db).searchLeads(const LeadQuery());
    expect(leads.map((l) => l.name), ['A', 'B']);
    expect(leads.last.phoneNormalized, isNull);
  });

  test('a failure while saving leaves no partial import', () async {
    final (container, db) = await createTestContainer();
    // Make the second row fail inside the transaction.
    await db.execute(
      'CREATE TRIGGER fail_on_boom BEFORE INSERT ON leads '
      "WHEN NEW.name = 'BOOM' BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    container.listen(importFlowProvider, (_, _) {});
    final flow = container.read(importFlowProvider.notifier);

    await flow.openFile(
      PickedFile(
        name: 'x.csv',
        bytes: csvBytes(
          'Name,Phone\nFirst,9876543210\nBOOM,9123456789\nLast,9000000003\n',
        ),
      ),
    );
    await flow.review();
    await flow.confirmImport();

    expect(await LeadRepository(db).searchLeads(const LeadQuery()), isEmpty);
    // Back on the review step so the user can try again.
    expect(container.read(importFlowProvider), isA<ImportReview>());
  });

  test('rejects unsupported and unreadable files', () async {
    final (container, _) = await createTestContainer();
    container.listen(importFlowProvider, (_, _) {});
    final flow = container.read(importFlowProvider.notifier);

    await flow.openFile(PickedFile(name: 'old.xls', bytes: csvBytes('x')));
    expect(
      (container.read(importFlowProvider) as ImportStart).error,
      contains('.xlsx'),
    );

    await flow.openFile(
      PickedFile(name: 'broken.xlsx', bytes: csvBytes('not a spreadsheet')),
    );
    expect(
      (container.read(importFlowProvider) as ImportStart).error,
      'This file could not be read as a spreadsheet.',
    );
  });

  test('back steps keep the mapping; restart clears everything', () async {
    final (container, _) = await createTestContainer();
    container.listen(importFlowProvider, (_, _) {});
    final flow = container.read(importFlowProvider.notifier);

    await flow.openFile(PickedFile(name: 'x.csv', bytes: csvBytes(csv)));
    flow.setColumn(LeadField.company, null);
    await flow.review();
    flow.backToMapping();

    final mapping = container.read(importFlowProvider) as ImportMapping;
    expect(mapping.mapping[LeadField.company], isNull);

    flow.restart();
    expect(container.read(importFlowProvider), isA<ImportStart>());
  });
}
