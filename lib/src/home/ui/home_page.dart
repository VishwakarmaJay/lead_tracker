import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/src/calls/providers/pending_call_provider.dart';
import 'package:lead_tracker/src/calls/ui/components/log_call_sheet.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/update/ui/components/patch_banner.dart';

/// Bottom-tab shell: Dashboard, Leads, Calls, Follow-ups, Settings.
///
/// Also hosts app-wide reactions that must work on every screen:
/// - the update banner above the navigation bar;
/// - opening Shared files when a share arrives;
/// - offering "Log call" when the user returns from a call started here.
@RoutePage()
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(pendingCallTrackerProvider.notifier).markLeftApp(),
      onResume: _offerToLogCall,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _offerToLogCall() async {
    final pending = ref
        .read(pendingCallTrackerProvider.notifier)
        .takeOnReturn();
    if (pending == null || !mounted) {
      return;
    }
    await showLogCallSheet(
      context,
      leadId: pending.leadId,
      leadName: pending.leadName,
      currentTemperature: pending.temperature,
      calledAt: pending.dialedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
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
