import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_detail_provider.dart';
import 'package:lead_tracker/src/leads/providers/lead_list_provider.dart';

import '../helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('list follows the filter', () async {
    final (container, db) = await createTestContainer();
    final repo = LeadRepository(db);
    await repo.createLead(const LeadDraft(name: 'Asha', phone: '1'));
    await repo.createLead(
      const LeadDraft(
        name: 'Bharat',
        phone: '2',
        temperature: LeadTemperature.hot,
      ),
    );
    container.listen(leadListProvider, (_, _) {});
    final filter = container.read(leadListFilterProvider.notifier);

    expect(await container.read(leadListProvider.future), hasLength(2));

    filter.setTemperature(LeadTemperature.hot);
    expect((await container.read(leadListProvider.future)).map((l) => l.name), [
      'Bharat',
    ]);

    filter
      ..setTemperature(null)
      ..setText('  ash ');
    expect(container.read(leadListFilterProvider).text, 'ash');
    expect((await container.read(leadListProvider.future)).map((l) => l.name), [
      'Asha',
    ]);

    filter.clearFilters();
    expect(container.read(leadListFilterProvider).text, 'ash');
  });

  test('detail: status and temperature changes are saved', () async {
    final (container, db) = await createTestContainer();
    final id = await LeadRepository(
      db,
    ).createLead(const LeadDraft(name: 'Asha', phone: '1'));
    container.listen(leadDetailProvider(id), (_, _) {});
    await container.read(leadDetailProvider(id).future);
    final notifier = container.read(leadDetailProvider(id).notifier);

    await notifier.setStatus(LeadStatus.proposalSent);
    await notifier.setTemperature(LeadTemperature.hot);

    final saved = (await LeadRepository(db).getLeadById(id))!;
    expect(saved.status, LeadStatus.proposalSent);
    expect(saved.temperature, LeadTemperature.hot);
  });

  test('detail: delete hides the lead, restore brings it back', () async {
    final (container, db) = await createTestContainer();
    final id = await LeadRepository(
      db,
    ).createLead(const LeadDraft(name: 'Asha', phone: '1'));
    container
      ..listen(leadDetailProvider(id), (_, _) {})
      ..listen(leadListProvider, (_, _) {});
    await container.read(leadDetailProvider(id).future);

    await container.read(leadDetailProvider(id).notifier).delete();
    expect(await container.read(leadDetailProvider(id).future), isNull);
    expect(await container.read(leadListProvider.future), isEmpty);

    await container.read(leadDetailProvider(id).notifier).restore();
    expect(await container.read(leadDetailProvider(id).future), isNotNull);
    expect(await container.read(leadListProvider.future), hasLength(1));
  });
}
