import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/permissions/screens/permission_screen.dart';
import '../../features/home/screens/home_dashboard_screen.dart';
import '../../features/screenshots/screens/screenshot_list_screen.dart';
import '../../features/screenshots/screens/screenshot_detail_screen.dart';
import '../../features/screenshots/screens/screenshot_viewer_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/categories/screens/category_screenshots_screen.dart';
import '../../features/expenses/screens/expense_dashboard_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Mirrors every imperative/declarative navigation event to the debug console
/// so route changes are traceable without enabling the noisy global
/// `debugLogDiagnostics` dump in release profiles.
class _AppNavigationLogObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('push ${_of(route)} (from ${_of(previousRoute)})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('pop ${_of(route)} (back to ${_of(previousRoute)})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('replace ${_of(oldRoute)} → ${_of(newRoute)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('remove ${_of(route)}');
  }

  static String _of(Route<dynamic>? route) =>
      route?.settings.name ?? route?.settings.arguments?.toString() ?? 'anon';

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[app_router nav] $message');
    }
  }
}

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    observers: [_AppNavigationLogObserver()],
    // Unknown locations must land on home, never on go_router's blank
    // default error page. (go_router allows only one exception hook, so the
    // error is surfaced from within this builder rather than onException.)
    errorBuilder: (context, state) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception:
              state.error ??
              StateError('GoRouter could not resolve "${state.uri}"'),
          library: 'router',
          silent: true,
        ),
      );
      return const HomeDashboardScreen();
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/permissions',
        builder: (_, _) => const PermissionScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeDashboardScreen()),
      GoRoute(
        path: '/screenshots',
        builder: (_, _) => const ScreenshotListScreen(),
      ),
      GoRoute(
        path: '/screenshots/:id',
        builder: (_, state) =>
            ScreenshotDetailScreen(screenshotId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/viewer/:id',
        builder: (_, state) => ScreenshotViewerScreen(
          screenshotId: state.pathParameters['id']!,
          categoryName: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/categories/:name',
        builder: (_, state) => CategoryScreenshotsScreen(
          categoryName: state.pathParameters['name']!,
        ),
      ),
      GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
      GoRoute(
        path: '/expenses',
        builder: (_, _) => const ExpenseDashboardScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
}
