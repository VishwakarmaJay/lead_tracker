import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/routes/app_router.dart';

/// Every `@RoutePage()` in lib/ must be registered in `AppRouter.routes`.
///
/// Codegen creates the `XRoute` class even when the page isn't registered,
/// so a missing registration compiles fine and only fails at runtime with
/// "Failed to navigate to XRoute". This test catches it.
void main() {
  Set<String> registeredNames(List<AutoRoute> routes) => {
    for (final route in routes) ...{
      route.name,
      ...registeredNames(route.children ?? const []),
    },
  };

  Set<String> annotatedPages() {
    final pattern = RegExp(r'@RoutePage\(\)\s*class\s+(\w+)Page\b');
    return {
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            !file.path.endsWith('.g.dart') &&
            !file.path.endsWith('.gr.dart'))
          for (final match in pattern.allMatches(file.readAsStringSync()))
            '${match.group(1)}Route',
    };
  }

  test('every @RoutePage is registered in AppRouter', () {
    final registered = registeredNames(AppRouter().routes);
    final pages = annotatedPages();

    expect(pages, isNotEmpty);
    expect(
      pages.difference(registered),
      isEmpty,
      reason: 'Register these in lib/src/routes/app_router.dart',
    );
  });

  test('lead routes are registered at the root, above the tabs', () {
    final rootNames = AppRouter().routes.map((r) => r.name).toSet();
    expect(rootNames, containsAll(['LeadDetailRoute', 'LeadFormRoute']));
  });
}
