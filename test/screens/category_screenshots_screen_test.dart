import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot_brain/core/theme/app_theme.dart';
import 'package:screenshot_brain/core/widgets/empty_state_widget.dart';
import 'package:screenshot_brain/core/widgets/error_widget.dart';
import 'package:screenshot_brain/core/widgets/loading_widget.dart';
import 'package:screenshot_brain/features/categories/providers/category_provider.dart';
import 'package:screenshot_brain/features/categories/screens/categories_screen.dart';
import 'package:screenshot_brain/features/categories/screens/category_screenshots_screen.dart';
import 'package:screenshot_brain/shared/models/screenshot_model.dart';

/// 1x1 transparent PNG written to a temp dir so Image.file decodes cleanly.
late final Directory _tmpDir;
late final String _pngA;
late final String _pngB;

ScreenshotModel _model({
  required int id,
  required String path,
  required String category,
}) => ScreenshotModel()
  ..id = id
  ..filePath = path
  ..category = category
  ..createdAt = DateTime(2026, 1, id);

/// Category names in the order their cards appear in the grid.
List<String> _renderedCardNames(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(GridView), matching: find.byType(Text)),
    )
    .map((text) => text.data)
    .whereType<String>()
    .where((data) => !data.contains('screenshot'))
    .toList();

/// Makes the viewport tall enough that the category grid builds every card
/// (GridView.builder culls off-screen children).
void _showFullGrid(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: ScreenshotBrainTheme.light, home: home),
    );

void main() {
  setUpAll(() {
    _tmpDir = Directory.systemTemp.createTempSync('sb_category_test');
    const pngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    final bytes = base64Decode(pngBase64);
    for (final name in ['a.png', 'b.png']) {
      File('${_tmpDir.path}/$name').writeAsBytesSync(bytes);
    }
    _pngA = '${_tmpDir.path}/a.png';
    _pngB = '${_tmpDir.path}/b.png';
  });

  tearDownAll(() => _tmpDir.deleteSync(recursive: true));

  group('CategoriesScreen', () {
    testWidgets('shows the shared LoadingWidget while counts are pending', (
      tester,
    ) async {
      final gate = Completer<Map<String, int>>();
      await tester.pumpWidget(
        _app(
          const CategoriesScreen(),
          overrides: [
            categoryCountsProvider.overrideWith((ref) => gate.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Loading categories...'), findsOneWidget);

      gate.complete(const {});
      await tester.pumpAndSettle();
      expect(find.byType(LoadingWidget), findsNothing);
    });

    testWidgets('a provider failure surfaces via AppErrorWidget and retry '
        're-runs the query', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        _app(
          const CategoriesScreen(),
          overrides: [
            categoryCountsProvider.overrideWith((ref) async {
              attempts++;
              throw StateError('isar closed');
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(
        find.text("We couldn't load your categories. Please try again."),
        findsOneWidget,
      );
      // Was a defect: this asserted the raw 'isar closed' dump on screen.
      expect(find.textContaining('isar closed'), findsNothing);

      await tester.tap(find.byKey(const Key('appErrorRetryButton')));
      await tester.pumpAndSettle();
      expect(attempts, greaterThan(1));
    });

    testWidgets('an empty library shows the empty state, not a blank grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const CategoriesScreen(),
          overrides: [
            categoryCountsProvider.overrideWith((ref) async => const {}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No categorized screenshots yet'), findsOneWidget);
    });

    testWidgets('renders the full category grid, zero-count categories '
        'included', (tester) async {
      await tester.pumpWidget(
        _app(
          const CategoriesScreen(),
          overrides: [
            categoryCountsProvider.overrideWith(
              (ref) async => const {'Bills': 2, 'Payments': 1},
            ),
          ],
        ),
      );
      _showFullGrid(tester);
      await tester.pumpAndSettle();

      expect(find.text('2 screenshots'), findsOneWidget);
      expect(find.text('1 screenshot'), findsOneWidget);
      // Every canonical category stays visible, even at zero.
      for (final category in kCategoryList) {
        expect(
          find.text(category),
          findsOneWidget,
          reason: '$category vanished from the grid',
        );
      }
    });

    testWidgets('cards follow the providers deterministic count order and '
        'surface categories outside the canonical vocabulary', (tester) async {
      await tester.pumpWidget(
        _app(
          const CategoriesScreen(),
          overrides: [
            categoryCountsProvider.overrideWith(
              (ref) async => const {'Zebra': 9, 'Bills': 5, 'Payments': 1},
            ),
          ],
        ),
      );
      _showFullGrid(tester);
      await tester.pumpAndSettle();

      // Unknown category first (highest count), then Bills, then Payments —
      // the sort categoryCountsProvider already performs must not be dropped
      // on the floor, and the Zebra rows must not silently vanish.
      expect(_renderedCardNames(tester).take(3).toList(), [
        'Zebra',
        'Bills',
        'Payments',
      ]);
      expect(find.text('9 screenshots'), findsOneWidget);
    });

    testWidgets('tapping a category card navigates with the exact category '
        'name, spaces included', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CategoriesScreen()),
          GoRoute(
            path: '/categories/:name',
            builder: (_, state) => CategoryScreenshotsScreen(
              categoryName: state.pathParameters['name']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryCountsProvider.overrideWith(
              (ref) async => const {'UPI Receipts': 3, 'Bills': 1},
            ),
            screenshotsByCategoryProvider.overrideWith(
              (ref, _) async => const [],
            ),
          ],
          child: MaterialApp.router(
            theme: ScreenshotBrainTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('UPI Receipts'));
      await tester.pumpAndSettle();

      final screen = tester.widget<CategoryScreenshotsScreen>(
        find.byType(CategoryScreenshotsScreen),
      );
      expect(screen.categoryName, 'UPI Receipts');
      expect(find.text('No UPI Receipts Screenshots'), findsOneWidget);
    });

    testWidgets('a category label containing path syntax still routes to '
        'itself', (tester) async {
      // Categories are free text once the categorizer meets an unknown
      // label, and the card interpolated the name straight into the route:
      // 'Bills/2026' matched /categories/Bills with a stray /2026 tail, and
      // 'Notes?draft' lost everything from the '?' onward to the query
      // parser. Both opened the wrong (or a nonexistent) screen.
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CategoriesScreen()),
          GoRoute(
            path: '/categories/:name',
            builder: (_, state) => CategoryScreenshotsScreen(
              categoryName: state.pathParameters['name']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryCountsProvider.overrideWith(
              (ref) async => const {'Bills/2026': 2, 'Notes?draft': 1},
            ),
            screenshotsByCategoryProvider.overrideWith(
              (ref, _) async => const [],
            ),
          ],
          child: MaterialApp.router(
            theme: ScreenshotBrainTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bills/2026'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CategoryScreenshotsScreen>(
              find.byType(CategoryScreenshotsScreen),
            )
            .categoryName,
        'Bills/2026',
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notes?draft'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CategoryScreenshotsScreen>(
              find.byType(CategoryScreenshotsScreen),
            )
            .categoryName,
        'Notes?draft',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long category label ellipsizes instead of overflowing the '
        'card', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const longLabel = 'Government Notifications And Circulars 2026';
      await tester.pumpWidget(
        _app(
          const CategoriesScreen(),
          overrides: [
            categoryCountsProvider.overrideWith(
              (ref) async => const {longLabel: 1, 'Bills': 2},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(longLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.text(longLabel));
      expect(title.overflow, TextOverflow.ellipsis);
      expect(title.maxLines, 1);
    });
  });

  group('CategoryScreenshotsScreen', () {
    Future<void> pumpCategory(
      WidgetTester tester, {
      required List<ScreenshotModel> screenshots,
      List<GoRoute> extraRoutes = const [],
      String category = 'Bills',
    }) async {
      final overrides = [
        screenshotsByCategoryProvider.overrideWith(
          (ref, _) async => screenshots,
        ),
      ];
      if (extraRoutes.isEmpty) {
        await tester.pumpWidget(
          _app(
            CategoryScreenshotsScreen(categoryName: category),
            overrides: overrides,
          ),
        );
      } else {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp.router(
              theme: ScreenshotBrainTheme.light,
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) =>
                        CategoryScreenshotsScreen(categoryName: category),
                  ),
                  ...extraRoutes,
                ],
              ),
            ),
          ),
        );
      }
    }

    testWidgets('shows the shared LoadingWidget while the query runs', (
      tester,
    ) async {
      final gate = Completer<List<ScreenshotModel>>();
      await tester.pumpWidget(
        _app(
          const CategoryScreenshotsScreen(categoryName: 'Bills'),
          overrides: [
            screenshotsByCategoryProvider.overrideWith((ref, _) => gate.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Loading Bills screenshots...'), findsOneWidget);

      gate.complete(const []);
      await tester.pumpAndSettle();
      expect(find.byType(LoadingWidget), findsNothing);
    });

    testWidgets('a failed query surfaces via AppErrorWidget and retry '
        're-runs it', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        _app(
          const CategoryScreenshotsScreen(categoryName: 'Notes'),
          overrides: [
            screenshotsByCategoryProvider.overrideWith((ref, _) async {
              attempts++;
              throw StateError('disk full');
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(
        find.text(
          "We couldn't load the screenshots in this category. "
          'Please try again.',
        ),
        findsOneWidget,
      );
      // Was a defect: this asserted the raw 'disk full' dump on screen.
      expect(find.textContaining('disk full'), findsNothing);

      await tester.tap(find.byKey(const Key('appErrorRetryButton')));
      await tester.pumpAndSettle();
      expect(attempts, greaterThan(1));
    });

    testWidgets('an empty category renders the empty state instead of '
        'crashing on a zero-length grid', (tester) async {
      await pumpCategory(tester, screenshots: const []);
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No Bills Screenshots'), findsOneWidget);
    });

    testWidgets('renders one grid tile per screenshot', (tester) async {
      final screenshots = [
        _model(id: 1, path: _pngA, category: 'Bills'),
        _model(id: 2, path: _pngB, category: 'Bills'),
      ];
      await pumpCategory(tester, screenshots: screenshots);
      await tester.pumpAndSettle();

      expect(find.byType(Hero), findsNWidgets(2));
      expect(find.text('Bills'), findsOneWidget);
    });

    testWidgets('tapping a tile opens the viewer with the screenshot id '
        'and a decodable category', (tester) async {
      await pumpCategory(
        tester,
        screenshots: [_model(id: 7, path: _pngA, category: 'Travel Tickets')],
        category: 'Travel Tickets',
        extraRoutes: [
          GoRoute(
            path: '/viewer/:id',
            builder: (_, state) => Scaffold(
              body: Text(
                'VIEWER|${state.pathParameters['id']}|'
                '${state.uri.queryParameters['category']}',
              ),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Hero).first);
      await tester.pumpAndSettle();

      expect(find.text('VIEWER|7|Travel Tickets'), findsOneWidget);
    });
  });
}
