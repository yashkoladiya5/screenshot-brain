import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/widgets/empty_state_widget.dart';
import 'package:screenshot_brain/core/widgets/error_widget.dart';
import 'package:screenshot_brain/core/widgets/loading_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

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
}
