import 'package:auto_route/auto_route.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
Raw<AppRouter> appRouter(Ref ref) => AppRouter();

/// The whole route tree. After adding a `@RoutePage`, register it here and run
/// `fvm dart run build_runner build --delete-conflicting-outputs`.
///
/// No auth guards: there is no login. Splash waits for startup, then replaces
/// itself with the home tabs.
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
      children: [
        AutoRoute(page: DashboardRoute.page, path: 'dashboard', initial: true),
        AutoRoute(page: LeadsRoute.page, path: 'leads'),
        AutoRoute(page: CallsRoute.page, path: 'calls'),
        AutoRoute(page: FollowUpsRoute.page, path: 'follow-ups'),
        AutoRoute(page: SettingsRoute.page, path: 'settings'),
      ],
    ),
    AutoRoute(page: LeadDetailRoute.page, path: '/leads/:id'),
    AutoRoute(page: LeadFormRoute.page, path: '/lead-form'),
    AutoRoute(page: SharedInboxRoute.page, path: '/shared-inbox'),
  ];
}
