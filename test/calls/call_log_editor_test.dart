import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/calls/providers/call_log_editor_provider.dart';
import 'package:lead_tracker/src/calls/providers/recent_calls_provider.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_timeline_provider.dart';

import '../helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logs a manual call, updates temperature, refreshes views', () async {
    final (container, db) = await createTestContainer();
    final leadId = await LeadRepository(db).createLead(
      const LeadDraft(
        name: 'Asha',
        phone: '98765 43210',
        phoneNormalized: '+919876543210',
      ),
    );
    container
      ..listen(callLogEditorProvider, (_, _) {})
      ..listen(leadTimelineProvider(leadId), (_, _) {})
      ..listen(recentCallsProvider, (_, _) {});
    expect(await container.read(leadTimelineProvider(leadId).future), isEmpty);

    final calledAt = DateTime(2026, 11, 24, 15);
    await container
        .read(callLogEditorProvider.notifier)
        .save(
          CallLogInput(
            leadId: leadId,
            calledAt: calledAt,
            durationSeconds: 300,
            disposition: CallDisposition.interested,
            summary: '  Budget 50k, wants a demo  ',
            newTemperature: LeadTemperature.hot,
          ),
        );

    final timeline = await container.read(leadTimelineProvider(leadId).future);
    final call = timeline.single;
    expect(call.source, CallSource.manual);
    expect(call.callType, CallType.outgoing);
    expect(call.summary, 'Budget 50k, wants a demo');
    expect(call.phone, '98765 43210');
    expect(call.phoneNormalized, '+919876543210');
    expect(call.displayName, 'Asha');
    expect(call.calledAt, calledAt.toUtc());

    final recent = await container.read(recentCallsProvider.future);
    expect(recent.single.leadName, 'Asha');

    final lead = (await LeadRepository(db).getLeadById(leadId))!;
    expect(lead.temperature, LeadTemperature.hot);
  });

  test('edits an existing call and can clear the outcome', () async {
    final (container, db) = await createTestContainer();
    final leadId = await LeadRepository(
      db,
    ).createLead(const LeadDraft(name: 'Asha', phone: '1'));
    final calls = CallLogRepository(db);
    final id = await calls.createCallLog(
      CallLogDraft(
        leadId: leadId,
        calledAt: DateTime.utc(2026, 11, 24),
        disposition: CallDisposition.busy,
      ),
    );
    final existing = (await calls.getCallLogById(id))!;
    container.listen(callLogEditorProvider, (_, _) {});

    await container
        .read(callLogEditorProvider.notifier)
        .save(
          CallLogInput(
            leadId: leadId,
            calledAt: existing.calledAt,
            callType: CallType.missed,
            summary: '',
          ),
          existing: existing,
        );

    final saved = (await calls.getCallLogById(id))!;
    expect(saved.callType, CallType.missed);
    expect(saved.disposition, isNull);
    expect(saved.summary, isNull);
  });

  test('recent calls keep calls of deleted leads, flagged', () async {
    final (container, db) = await createTestContainer();
    final leads = LeadRepository(db);
    final leadId = await leads.createLead(
      const LeadDraft(name: 'Asha', phone: '1'),
    );
    await CallLogRepository(
      db,
    ).createCallLog(CallLogDraft(leadId: leadId, calledAt: DateTime.utc(2026)));
    await CallLogRepository(
      db,
    ).createCallLog(CallLogDraft(calledAt: DateTime.utc(2025), phone: '999'));
    await leads.deleteLead(leadId);

    container.listen(recentCallsProvider, (_, _) {});
    final recent = await container.read(recentCallsProvider.future);
    expect(recent.first.leadDeleted, isTrue);
    expect(recent.last.leadName, isNull);
    expect(recent.last.call.phone, '999');
  });
}
