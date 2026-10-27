import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/widgets/empty_state_widget.dart';
import 'package:screenshot_brain/core/widgets/error_widget.dart';
import 'package:screenshot_brain/core/widgets/loading_widget.dart';
import 'package:screenshot_brain/features/expenses/models/expense_item.dart';
import 'package:screenshot_brain/features/home/providers/home_provider.dart';
import 'package:screenshot_brain/features/home/screens/home_dashboard_screen.dart';
import 'package:screenshot_brain/features/screenshots/providers/screenshot_provider.dart';

Widget _wrap(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(home: child),
);

/// Records scan taps without touching the real Isar-backed scan pipeline.
class _RecordingScanNotifier extends ScanScreenshotsNotifier {
  int scanCalls = 0;

  @override
  Future<void> scan() async {
    scanCalls++;
  }
}

void main() {
  group('HomeDashboardScreen', () {
    testWidgets('shows the shared loading widget while stats are pending', (
      tester,
    ) async {
      final gate = Completer<HomeStats>();
      await tester.pumpWidget(
        _wrap(const HomeDashboardScreen(), [
          homeStatsProvider.overrideWith((ref) => gate.future),
        ]),
      );

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Loading your dashboard...'), findsOneWidget);

      // Resolve before teardown so nothing dangles.
      gate.complete(
        const HomeStats(
          screenshotCount: 1,
          expenseCount: 0,
          unprocessedCount: 0,
          totalExpenses: 0,
          recentExpenses: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoadingWidget), findsNothing);
    });

    testWidgets(
      'empty home state renders the shared widget and triggers a scan',
      (tester) async {
        const stats = HomeStats(
          screenshotCount: 0,
          expenseCount: 0,
          unprocessedCount: 0,
          totalExpenses: 0,
          recentExpenses: [],
        );
        final scanNotifier = _RecordingScanNotifier();
        await tester.pumpWidget(
          _wrap(const HomeDashboardScreen(), [
            homeStatsProvider.overrideWith((ref) async => stats),
            scanScreenshotsProvider.overrideWith(() => scanNotifier),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EmptyStateWidget), findsOneWidget);
        expect(find.text('No screenshots yet'), findsOneWidget);

        await tester.tap(find.byKey(const Key('homeScanAction')));
        await tester.pump();
        expect(scanNotifier.scanCalls, 1);
      },
    );

    testWidgets('surfaces errors through AppErrorWidget with a working retry', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        _wrap(const HomeDashboardScreen(), [
          homeStatsProvider.overrideWith((ref) async {
            attempts++;
            throw StateError('database unavailable');
          }),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
      // The user sees a short, actionable sentence...
      expect(
        find.text("We couldn't load your dashboard. Please try again."),
        findsOneWidget,
      );
      // ...and the raw exception dump is NOT leaked into the widget tree
      // (it is debugPrint-ed to the logs instead). This assertion was the
      // defect: it used to require `database unavailable` on screen.
      expect(find.textContaining('database unavailable'), findsNothing);

      await tester.tap(find.byKey(const Key('appErrorRetryButton')));
      await tester.pumpAndSettle();

      // Retry invalidates homeStatsProvider, forcing a fresh (failed) build.
      expect(attempts, greaterThan(1));
    });

    testWidgets(
      'renders snapshot-derived counts, monthly total and breakdown',
      (tester) async {
        final recent = [
          ExpenseItem(
            id: 1,
            screenshotId: 10,
            amount: 250,
            merchant: 'BigBasket',
            category: 'Food',
            expenseDate: DateTime(2026, 2, 3),
            createdAt: DateTime(2026, 2, 3),
          ),
        ];
        final stats = HomeStats(
          screenshotCount: 42,
          expenseCount: 7,
          unprocessedCount: 5,
          totalExpenses: 4800,
          monthlyExpenses: 1500,
          expensesByCategory: const {'Food': 1200.0, 'Bills': 3600.0},
          recentExpenses: recent,
        );
        await tester.pumpWidget(
          _wrap(const HomeDashboardScreen(), [
            homeStatsProvider.overrideWith((ref) async => stats),
          ]),
        );
        await tester.pumpAndSettle();

        // Shared loading / empty / error widgets are absent in the data state.
        expect(find.byType(LoadingWidget), findsNothing);
        expect(find.byType(EmptyStateWidget), findsNothing);
        expect(find.byType(AppErrorWidget), findsNothing);

        // Counts + monthly total from the single expense snapshot scan.
        expect(find.text('42'), findsOneWidget);
        expect(find.text('This Month'), findsOneWidget);
        expect(find.text('\u20b91,500'), findsOneWidget);
        expect(find.text('\u20b94,800'), findsOneWidget);

        // Scroll the snapshot-derived sections into view.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();

        // Category breakdown reuses snapshot.byCategory, largest first.
        expect(find.text('Top Categories'), findsOneWidget);
        expect(find.text('Bills'), findsOneWidget);
        expect(find.text('\u20b93,600'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('BigBasket'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Recent expenses rendered from snapshot.recent.
        expect(find.text('Recent Expenses'), findsOneWidget);
        expect(find.text('BigBasket'), findsOneWidget);
      },
    );

    testWidgets(
      'top categories break total ties by name, not map insertion order',
      (tester) async {
        // Tied amounts inserted Food-first: a UI-level re-sort with only an
        // amount comparator keeps the map's iteration order, so the rendered
        // sequence silently changes with input order. Canonical order is
        // amount desc, name asc — matching the expense snapshot's contract —
        // so the same data must always render Bills above Food.
        final stats = HomeStats(
          screenshotCount: 10,
          expenseCount: 2,
          unprocessedCount: 0,
          totalExpenses: 1000,
          monthlyExpenses: 1000,
          expensesByCategory: const {'Food': 500.0, 'Bills': 500.0},
          recentExpenses: const [],
        );
        await tester.pumpWidget(
          _wrap(HomeDashboardScreen(), [
            homeStatsProvider.overrideWith((ref) async => stats),
          ]),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(
          tester.getTopLeft(find.text('Bills')).dy,
          lessThan(tester.getTopLeft(find.text('Food')).dy),
          reason: 'equally-spending Bills must render above Food',
        );
      },
    );

    testWidgets('top categories stay amount-descending when totals differ', (
      tester,
    ) async {
      final stats = HomeStats(
        screenshotCount: 10,
        expenseCount: 2,
        unprocessedCount: 0,
        totalExpenses: 4800,
        monthlyExpenses: 4800,
        expensesByCategory: const {'Food': 1200.0, 'Bills': 3600.0},
        recentExpenses: const [],
      );
      await tester.pumpWidget(
        _wrap(HomeDashboardScreen(), [
          homeStatsProvider.overrideWith((ref) async => stats),
        ]),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Bills')).dy,
        lessThan(tester.getTopLeft(find.text('Food')).dy),
      );
    });
  });
}
