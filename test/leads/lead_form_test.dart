import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/utils/phone_normalizer.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_form_provider.dart';
import 'package:lead_tracker/src/leads/providers/lead_list_provider.dart';

import '../helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('validators', () {
    test('name is required and limited', () {
      expect(validateLeadName(''), isNotNull);
      expect(validateLeadName('   '), isNotNull);
      expect(validateLeadName('A' * (maxLeadNameLength + 1)), isNotNull);
      expect(validateLeadName('Asha'), isNull);
    });

    test('phone is required and needs digits', () {
      expect(validateLeadPhone(''), isNotNull);
      expect(validateLeadPhone('call me'), isNotNull);
      expect(validateLeadPhone('12'), isNull); // kept, but flagged later
    });

    test('email is optional but must look complete', () {
      expect(validateLeadEmail(''), isNull);
      expect(validateLeadEmail('asha@pixel.in'), isNull);
      expect(validateLeadEmail('asha@pixel'), isNotNull);
      expect(validateLeadEmail('asha pixel.in'), isNotNull);
    });
  });

  test('draft trims text, turns blanks into null, normalises phone', () {
    final draft = leadDraftFromInput(
      const LeadFormInput(
        name: '  Asha Rao ',
        phone: ' 98765 43210 ',
        company: '  ',
        email: ' asha@pixel.in ',
        notes: '\n',
      ),
      const PhoneNormalizer(),
    );
    expect(draft.name, 'Asha Rao');
    expect(draft.phone, '98765 43210');
    expect(draft.phoneNormalized, '+919876543210');
    expect(draft.company, isNull);
    expect(draft.email, 'asha@pixel.in');
    expect(draft.notes, isNull);
  });

  group('LeadEditor', () {
    test('creates a lead and refreshes the list', () async {
      final (container, _) = await createTestContainer();
      container
        ..listen(leadEditorProvider, (_, _) {})
        ..listen(leadListProvider, (_, _) {});
      expect(await container.read(leadListProvider.future), isEmpty);

      final id = await container
          .read(leadEditorProvider.notifier)
          .save(const LeadFormInput(name: 'Asha', phone: '09876543210'));

      final leads = await container.read(leadListProvider.future);
      expect(leads.single.id, id);
      expect(leads.single.phoneNormalized, '+919876543210');
      expect(container.read(leadEditorProvider), isFalse);
    });

    test('updates every field, including clearing optional ones', () async {
      final (container, db) = await createTestContainer();
      container.listen(leadEditorProvider, (_, _) {});
      final editor = container.read(leadEditorProvider.notifier);
      final id = await editor.save(
        const LeadFormInput(name: 'Asha', phone: '9876543210', company: 'Old'),
      );
      final lead = (await LeadRepository(db).getLeadById(id))!;

      await editor.save(
        const LeadFormInput(
          name: 'Asha Rao',
          phone: 'not a number 1',
          status: LeadStatus.qualified,
        ),
        existing: lead,
      );

      final saved = (await LeadRepository(db).getLeadById(id))!;
      expect(saved.name, 'Asha Rao');
      expect(saved.company, isNull);
      expect(saved.status, LeadStatus.qualified);
      expect(saved.phoneNormalized, isNull);
    });

    test('finds other leads with the same number', () async {
      final (container, _) = await createTestContainer();
      container.listen(leadEditorProvider, (_, _) {});
      final editor = container.read(leadEditorProvider.notifier);
      final first = await editor.save(
        const LeadFormInput(name: 'Asha', phone: '9876543210'),
      );

      final dupes = await editor.findDuplicates('+91 98765 43210');
      expect(dupes.map((l) => l.id), [first]);
      expect(
        await editor.findDuplicates('9876543210', exceptLeadId: first),
        isEmpty,
      );
      expect(await editor.findDuplicates('12'), isEmpty);
      expect(editor.isPhoneRecognised('12'), isFalse);
    });
  });
}
