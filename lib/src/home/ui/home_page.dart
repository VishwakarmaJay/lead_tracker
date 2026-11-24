import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/update/ui/components/patch_banner.dart';

/// Bottom-tab shell: Dashboard, Leads, Calls, Follow-ups, Settings.
///
/// The update banner sits above the navigation bar so it shows on every tab.
@RoutePage()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Leads',
    ),
    NavigationDestination(
      icon: Icon(Icons.call_outlined),
      selectedIcon: Icon(Icons.call),
      label: 'Calls',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: 'Follow-ups',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A share arriving while the app is open opens the shared-files screen.
    ref.listen(sharedInboxProvider, (previous, next) {
      if (next.length > (previous?.length ?? 0) &&
          context.router.current.name != SharedInboxRoute.name) {
        context.router.push(const SharedInboxRoute());
      }
    });

    return AutoTabsRouter(
      routes: const [
        DashboardRoute(),
        LeadsRoute(),
        CallsRoute(),
        FollowUpsRoute(),
        SettingsRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          body: child,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PatchBanner(),
              NavigationBar(
                selectedIndex: tabsRouter.activeIndex,
                onDestinationSelected: tabsRouter.setActiveIndex,
                destinations: _destinations,
              ),
            ],
          ),
        );
      },
    );
  }
}
