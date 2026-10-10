import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';

class ScreenshotBrainApp extends ConsumerWidget {
  const ScreenshotBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.router;
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Screenshot Brain',
      debugShowCheckedModeBanner: false,
      theme: ScreenshotBrainTheme.light,
      darkTheme: ScreenshotBrainTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
