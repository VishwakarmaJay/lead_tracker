import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/app_restarter.dart';
import 'package:lead_tracker/core/instances/shorebird_instance.dart';
import 'package:lead_tracker/src/shared/providers/busy_operations_provider.dart';
import 'package:lead_tracker/src/theme/app_theme.dart';
import 'package:lead_tracker/src/update/ui/components/patch_banner.dart';

import 'fakes.dart';

void main() {
  Future<ProviderContainer> pumpBanner(
    WidgetTester tester,
    FakeShorebird shorebird, {
    FakeRestarter? restarter,
  }) async {
    final container = ProviderContainer(
      overrides: [
        shorebirdProvider.overrideWithValue(shorebird),
        appRestarterProvider.overrideWithValue(restarter ?? FakeRestarter()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(bottomNavigationBar: PatchBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows nothing when no patch is pending', (tester) async {
    await pumpBanner(tester, FakeShorebird());
    expect(find.text('A new update is available'), findsNothing);
    expect(find.text('Update ready'), findsNothing);
  });

  testWidgets('Update downloads, then Restart now restarts', (tester) async {
    final restarter = FakeRestarter();
    await pumpBanner(
      tester,
      FakeShorebird(availableForDownload: true),
      restarter: restarter,
    );

    expect(find.text('A new update is available'), findsOneWidget);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Update ready'), findsOneWidget);
    await tester.tap(find.text('Restart now'));
    await tester.pumpAndSettle();

    expect(restarter.calls, 1);
  });

  testWidgets('Restart now is disabled while an import is running', (
    tester,
  ) async {
    final restarter = FakeRestarter();
    final container = await pumpBanner(
      tester,
      FakeShorebird(readyToInstall: true),
      restarter: restarter,
    );

    final gate = Completer<void>();
    final running = container
        .read(busyOperationsProvider.notifier)
        .track(() => gate.future);
    await tester.pump();

    await tester.tap(find.text('Restart now'));
    await tester.pump();
    expect(restarter.calls, 0);

    gate.complete();
    await running;
    await tester.pump();

    await tester.tap(find.text('Restart now'));
    await tester.pump();
    expect(restarter.calls, 1);
  });
}
