import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';

import '../helpers/test_database.dart';

void main() {
  late TestClock clock;
  late LeadRepository repo;

  setUp(() async {
    clock = TestClock();
    repo = LeadRepository(await openTestDatabase(), now: clock.call);
  });

  Future<int> add(
    String name, {
    String phone = '9876543210',
    String? normalized = '+919876543210',
    String? company,
    String? email,
    LeadStatus status = LeadStatus.newLead,
    LeadTemperature temperature = LeadTemperature.unrated,
  }) {
    return repo.createLead(
      LeadDraft(
        name: name,
        phone: phone,
        phoneNormalized: normalized,
        company: company,
        email: email,
        status: status,
        temperature: temperature,
      ),
    );
  }

  test('creates and reads a lead with UTC timestamps', () async {
    final id = await add('Asha Rao', company: 'Rao Studio');
    final lead = (await repo.getLeadById(id))!;

    expect(lead.name, 'Asha Rao');
    expect(lead.phone, '9876543210');
    expect(lead.phoneNormalized, '+919876543210');
    expect(lead.company, 'Rao Studio');
    expect(lead.status, LeadStatus.newLead);
    expect(lead.temperature, LeadTemperature.unrated);
    expect(lead.createdAt, clock.current);
    expect(lead.createdAt.isUtc, isTrue);
    expect(lead.isDeleted, isFalse);
  });

  test(
    'update saves fields, can clear nullable ones, bumps updated_at',
    () async {
      final id = await add('Asha', company: 'Old Co');
      final lead = (await repo.getLeadById(id))!;

      clock.advance(const Duration(hours: 1));
      await repo.updateLead(
        lead.copyWith(
          status: LeadStatus.proposalSent,
          temperature: LeadTemperature.hot,
          company: () => null,
          notes: () => 'Wants a quote',
        ),
      );

      final saved = (await repo.getLeadById(id))!;
      expect(saved.status, LeadStatus.proposalSent);
      expect(saved.temperature, LeadTemperature.hot);
      expect(saved.company, isNull);
      expect(saved.notes, 'Wants a quote');
      expect(saved.updatedAt, clock.current);
      expect(saved.createdAt, lead.createdAt);
    },
  );

  group('search', () {
    setUp(() async {
      await add('Asha Rao', company: 'Pixel Works', email: 'asha@pixel.in');
      await add(
        'bharat shah',
        phone: '+91 91234 56789',
        normalized: '+919123456789',
        status: LeadStatus.contacted,
        temperature: LeadTemperature.hot,
      );
      await add('Chitra 100%', normalized: null);
    });

    Future<List<String>> names(LeadQuery query) async =>
        (await repo.searchLeads(query)).map((l) => l.name).toList();

    test('lists active leads sorted by name, case-insensitive', () async {
      expect(await names(const LeadQuery()), [
        'Asha Rao',
        'bharat shah',
        'Chitra 100%',
      ]);
    });

    test('matches name, company, email and phone', () async {
      expect(await names(const LeadQuery(text: 'pixel')), ['Asha Rao']);
      expect(await names(const LeadQuery(text: 'asha@')), ['Asha Rao']);
      expect(await names(const LeadQuery(text: 'SHAH')), ['bharat shah']);
      expect(await names(const LeadQuery(text: '91234')), ['bharat shah']);
      expect(await names(const LeadQuery(text: '+91912')), ['bharat shah']);
    });

    test('treats % and _ in the search text literally', () async {
      expect(await names(const LeadQuery(text: '100%')), ['Chitra 100%']);
      expect(await names(const LeadQuery(text: '%')), ['Chitra 100%']);
      expect(await names(const LeadQuery(text: '_')), isEmpty);
    });

    test('filters by status and temperature', () async {
      expect(await names(const LeadQuery(status: LeadStatus.contacted)), [
        'bharat shah',
      ]);
      expect(await names(const LeadQuery(temperature: LeadTemperature.hot)), [
        'bharat shah',
      ]);
      expect(
        await names(
          const LeadQuery(
            status: LeadStatus.newLead,
            temperature: LeadTemperature.hot,
          ),
        ),
        isEmpty,
      );
    });

    test('pages with limit and offset', () async {
      expect(await names(const LeadQuery(limit: 2, offset: 1)), [
        'bharat shah',
        'Chitra 100%',
      ]);
    });
  });

  test('soft delete hides the lead; restore brings it back', () async {
    final id = await add('Asha');

    await repo.deleteLead(id);
    expect(await repo.getLeadById(id), isNull);
    expect(
      (await repo.getLeadById(id, includeDeleted: true))!.isDeleted,
      isTrue,
    );
    expect(await repo.searchLeads(const LeadQuery()), isEmpty);
    expect(
      await repo.searchLeads(const LeadQuery(includeDeleted: true)),
      hasLength(1),
    );

    await repo.restoreLead(id);
    expect(await repo.getLeadById(id), isNotNull);
  });

  test('updating or deleting a deleted lead fails clearly', () async {
    final id = await add('Asha');
    final lead = (await repo.getLeadById(id))!;
    await repo.deleteLead(id);

    final isDatabaseError = throwsA(
      isA<AppException>().having((e) => e.type, 'type', ErrorType.database),
    );
    expect(repo.updateLead(lead), isDatabaseError);
    expect(repo.deleteLead(id), isDatabaseError);
  });

  test(
    'findByNormalizedPhone returns every active lead with that number',
    () async {
      await add('Asha');
      await add('Asha (office)');
      final deleted = await add('Old Asha');
      await add('Other', normalized: '+919000000000');
      await repo.deleteLead(deleted);

      final matches = await repo.findByNormalizedPhone('+919876543210');
      expect(matches.map((l) => l.name), ['Asha', 'Asha (office)']);
    },
  );

  test('createLeads inserts all rows in one transaction', () async {
    final ids = await repo.createLeads(const [
      LeadDraft(name: 'A', phone: '1'),
      LeadDraft(name: 'B', phone: '2'),
    ]);
    expect(ids, hasLength(2));
    expect(await repo.searchLeads(const LeadQuery()), hasLength(2));
  });

  test('LeadQuery is value-equal (safe as a provider family key)', () {
    expect(
      const LeadQuery(text: 'a', status: LeadStatus.won),
      const LeadQuery(text: 'a', status: LeadStatus.won),
    );
    expect(
      const LeadQuery(text: 'a').hashCode,
      const LeadQuery(text: 'a').hashCode,
    );
  });
}
