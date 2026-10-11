import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot_brain/core/router/app_router.dart';

void main() {
  // RouteConfiguration.findMatch is the same matching engine the router's
  // platform path parser runs on; it can be exercised without a widget tree.
  RouteMatchList resolve(String location) =>
      AppRouter.router.configuration.findMatch(Uri.parse(location));

  group('Router boots at the splash route', () {
    test('the route table is rooted at "/" and keeps every entry', () {
      // GoRouter keeps its initial (unattached) configuration empty, so
      // assert the routing table itself instead of the live delegate.
      final routes = AppRouter.router.configuration.routes;
      expect(routes, hasLength(11));
      expect((routes.first as GoRoute).path, '/');
      expect(resolve('/').matches.last.matchedLocation, '/');
    });
  });

  group('All existing route paths still resolve', () {
    // Every path that screens push/go to today (kept byte-identical).
    const staticPaths = [
      '/',
      '/permissions',
      '/home',
      '/screenshots',
      '/search',
      '/categories',
      '/expenses',
      '/settings',
    ];

    for (final path in staticPaths) {
      test('$path matches without an error', () {
        final list = resolve(path);
        expect(list.error, isNull, reason: '$path unexpectedly errored');
        expect(list.matches, isNotEmpty);
        expect(list.matches.last.matchedLocation, path);
      });
    }

    test('parameterised routes resolve and expose their parameters', () {
      final detail = resolve('/screenshots/abc-123');
      expect(detail.error, isNull);
      expect(detail.matches.last.matchedLocation, '/screenshots/abc-123');
      expect(detail.pathParameters['id'], 'abc-123');

      final viewer = resolve('/viewer/xyz?category=Bills');
      expect(viewer.error, isNull);
      expect(viewer.matches.last.matchedLocation, '/viewer/xyz');
      expect(viewer.pathParameters['id'], 'xyz');
      expect(viewer.uri.queryParameters['category'], 'Bills');

      final category = resolve('/categories/Payments');
      expect(category.error, isNull);
      expect(category.pathParameters['name'], 'Payments');
    });
  });

  group('Unknown routes degrade instead of blank-screening', () {
    test(
      'unmatched location yields a routing error for the fallback layer',
      () {
        // go_router reports the miss on the match list; AppRouter answers it
        // from errorBuilder with the home fallback (plus a FlutterError log)
        // rather than an exception, so matching itself must not throw.
        final list = resolve('/definitely/not/a/route');
        expect(list.matches, isEmpty);
        expect(list.error, isA<GoException>());
      },
    );
  });
}
