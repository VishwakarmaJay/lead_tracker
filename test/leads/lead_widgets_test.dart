import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/phone_launcher.dart';
import 'package:lead_tracker/core/utils/phone_normalizer.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_tile.dart';
import 'package:lead_tracker/src/leads/ui/lead_form_page.dart';
import 'package:lead_tracker/src/shared/providers/phone_normalizer_provider.dart';
import 'package:lead_tracker/src/theme/app_theme.dart';

import '../helpers/fake_launcher.dart';

Widget _app(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(theme: buildAppTheme(Brightness.light), home: child),
  );
}

void main() {
  testWidgets('form shows required-field errors and phone hints', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const LeadFormPage(),
        overrides: [
          phoneNormalizerProvider.overrideWithValue(const PhoneNormalizer()),
        ],
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a name.'), findsOneWidget);
    expect(find.text('Enter a phone number.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone *'),
      '98765 43210',
    );
    await tester.pump();
    expect(find.text('Saved for matching as +919876543210'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone *'),
      '12345',
    );
    await tester.pump();
    expect(find.textContaining("Can't recognise this number"), findsOneWidget);
  });

  testWidgets('call button on a lead row opens the dialer', (tester) async {
    final opener = FakeOpener();
    final lead = Lead(
      id: 1,
      name: 'Asha Rao',
      phone: '98765 43210',
      phoneNormalized: '+919876543210',
      company: 'Pixel Works',
      status: LeadStatus.contacted,
      temperature: LeadTemperature.hot,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      _app(
        Scaffold(body: LeadTile(lead: lead)),
        overrides: [phoneLauncherProvider.overrideWithValue(opener.launcher)],
      ),
    );

    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Contacted'), findsOneWidget);
    expect(find.text('Pixel Works · 98765 43210'), findsOneWidget);

    await tester.tap(find.byTooltip('Call Asha Rao'));
    await tester.pump();
    expect(opener.opened.single.toString(), 'tel:+919876543210');
  });
}
