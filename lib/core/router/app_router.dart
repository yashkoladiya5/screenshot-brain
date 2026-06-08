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

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeDashboardScreen()),
      GoRoute(path: '/screenshots', builder: (_, __) => const ScreenshotListScreen()),
      GoRoute(
        path: '/screenshots/:id',
        builder: (_, state) => ScreenshotDetailScreen(
          screenshotId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/viewer/:id',
        builder: (_, state) => ScreenshotViewerScreen(
          screenshotId: state.pathParameters['id']!,
          categoryName: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: '/categories/:name',
        builder: (_, state) => CategoryScreenshotsScreen(
          categoryName: state.pathParameters['name']!,
        ),
      ),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
      GoRoute(path: '/expenses', builder: (_, __) => const ExpenseDashboardScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
}
