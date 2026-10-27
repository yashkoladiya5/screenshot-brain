import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/design/tokens.dart';
import 'package:screenshot_brain/core/widgets/empty_state_widget.dart';
import 'package:screenshot_brain/core/widgets/error_widget.dart';
import 'package:screenshot_brain/core/widgets/loading_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// A realistic worst case: screens pass `error.toString()` straight through,
/// so the message can be a very long, whitespace-free technical dump.
const _longMessage =
    'Exception: HandledError(sqlite3_exception: unable to open database file '
    '(SQLITE_CANTOPEN) while running SELECT screenshots.id, screenshots.source '
    'FROM screenshots ORDER BY screenshots.captured_at DESC LIMIT 500 offset 0 '
    'in /data/user/0/com.example/database.sqlite) at ocr_service.dart:712';

/// Pumps [child] on the smallest surface the app realistically renders on
/// (a 320x480 logical viewport) and returns the taken framework exception,
/// if any (a RenderFlex overflow reports itself here).
Future<Object?> _pumpOnSmallSurface(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(320, 480));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetDevicePixelRatio());

  await tester.pumpWidget(_wrap(child));
  await tester.pump();
  return tester.takeException();
}

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders title, subtitle and icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EmptyStateWidget(
            icon: Icons.photo_library_outlined,
            title: 'No screenshots yet',
            subtitle: 'Capture something to get started',
          ),
        ),
      );

      expect(find.text('No screenshots yet'), findsOneWidget);
      expect(find.text('Capture something to get started'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('action button fires onAction callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Empty inbox',
            actionLabel: 'Scan now',
            onAction: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Scan now'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('no button when only one half of the action pair is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Empty inbox',
            actionLabel: 'Scan now',
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('custom action widget takes precedence', (tester) async {
      await tester.pumpWidget(
        _wrap(
          EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Empty inbox',
            actionLabel: 'Ignored',
            onAction: () {},
            action: ElevatedButton(
              onPressed: () {},
              child: const Text('Custom CTA'),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Custom CTA'), findsOneWidget);
      expect(find.text('Ignored'), findsNothing);
    });

    testWidgets('exposes an accessible default semantics label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Empty inbox',
            subtitle: 'Nothing here',
          ),
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel(RegExp('Empty inbox. Nothing here')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('AppErrorWidget', () {
    testWidgets('renders message and default icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppErrorWidget(message: 'OCR failed')),
      );

      expect(find.text('OCR failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('retry callback fires when the retry button is tapped', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        _wrap(AppErrorWidget(message: 'Scan failed', onRetry: () => retries++)),
      );

      final retryButton = find.byKey(const Key('appErrorRetryButton'));
      expect(retryButton, findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();
      await tester.tap(retryButton);
      await tester.pump();

      expect(retries, 2);
    });

    testWidgets('supports custom icon, title and retry label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppErrorWidget(
            message: 'Network unreachable',
            title: 'Connection problem',
            icon: Icons.wifi_off_rounded,
            retryLabel: 'Reconnect',
            onRetry: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
      expect(find.text('Connection problem'), findsOneWidget);
      expect(find.text('Network unreachable'), findsOneWidget);
      // FilledButton.icon renders as a private subclass, so match by key + label text.
      expect(find.byKey(const Key('appErrorRetryButton')), findsOneWidget);
      expect(find.text('Reconnect'), findsOneWidget);
    });

    testWidgets('exposes the message via semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const AppErrorWidget(
            message: 'Database locked',
            semanticsLabel: 'Error: Database locked',
          ),
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel(RegExp('Error: Database locked')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('LoadingWidget', () {
    testWidgets('renders spinner and optional message', (tester) async {
      await tester.pumpWidget(
        _wrap(const LoadingWidget(message: 'Scanning screenshots...')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Scanning screenshots...'), findsOneWidget);
    });

    testWidgets('renders without a message', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingWidget()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('optional icon customization', (tester) async {
      await tester.pumpWidget(
        _wrap(const LoadingWidget(icon: Icons.search_rounded)),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('exposes an accessible semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const LoadingWidget(message: 'Loading OCR')),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel(RegExp('Loading. Loading OCR')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('small-screen (320x480) robustness', () {
    testWidgets('long error message with title and retry does not overflow', (
      tester,
    ) async {
      final exception = await _pumpOnSmallSurface(
        tester,
        AppErrorWidget(
          message: _longMessage,
          title: 'Could not load screenshots',
          onRetry: () {},
        ),
      );

      expect(exception, isNull, reason: 'RenderFlex overflow on 320x480');
      expect(find.text(_longMessage), findsOneWidget);
    });

    testWidgets('long empty state copy with action does not overflow', (
      tester,
    ) async {
      final exception = await _pumpOnSmallSurface(
        tester,
        EmptyStateWidget(
          icon: Icons.photo_library_outlined,
          title: _longMessage,
          subtitle: _longMessage,
          actionLabel: 'Start a manual scan instead',
          onAction: () {},
        ),
      );

      expect(exception, isNull, reason: 'RenderFlex overflow on 320x480');
    });

    testWidgets('long loading message does not overflow', (tester) async {
      final exception = await _pumpOnSmallSurface(
        tester,
        const LoadingWidget(
          message: _longMessage,
          icon: Icons.dashboard_rounded,
        ),
      );

      expect(exception, isNull, reason: 'RenderFlex overflow on 320x480');
    });

    testWidgets('accessibility text scaling does not clip the error state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(3.0)),
            child: child!,
          ),
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Could not read the screenshot database',
              title: 'Something went wrong',
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('appErrorRetryButton')));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'error retry remains reachable after scrolling on small surface',
      (tester) async {
        await _pumpOnSmallSurface(
          tester,
          AppErrorWidget(message: _longMessage, onRetry: () {}),
        );

        final retry = find.byKey(const Key('appErrorRetryButton'));
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();

        expect(tester.getRect(retry).bottom, lessThanOrEqualTo(480));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('touch targets and consistency', () {
    testWidgets('error retry button meets the 44dp minimum touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AppErrorWidget(message: 'Boom', onRetry: () {})),
      );

      final rect = tester.getRect(find.byKey(const Key('appErrorRetryButton')));
      expect(rect.height, greaterThanOrEqualTo(SBSizes.minTouchTarget));
    });

    testWidgets('empty state action meets the 44dp minimum touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Empty inbox',
            actionLabel: 'Scan now',
            onAction: () {},
          ),
        ),
      );

      final rect = tester.getRect(find.byType(FilledButton));
      expect(rect.height, greaterThanOrEqualTo(SBSizes.minTouchTarget));
    });

    testWidgets('the family uses one action gap above the button slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AppErrorWidget(message: 'Boom', onRetry: () {})),
      );
      final errorGap =
          tester.getRect(find.byKey(const Key('appErrorRetryButton'))).top -
          tester.getRect(find.text('Boom')).bottom;

      await tester.pumpWidget(
        _wrap(
          EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Empty inbox',
            subtitle: 'Nothing here',
            actionLabel: 'Scan now',
            onAction: () {},
          ),
        ),
      );
      final emptyGap =
          tester.getRect(find.byType(FilledButton)).top -
          tester.getRect(find.text('Nothing here')).bottom;

      expect(
        errorGap,
        emptyGap,
        reason: 'screens should not have to special-case spacing',
      );
    });
  });
}
