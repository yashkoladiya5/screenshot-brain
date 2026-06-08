import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ScreenshotBrainApp extends StatelessWidget {
  const ScreenshotBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    return MaterialApp.router(
      title: 'Screenshot Brain',
      debugShowCheckedModeBanner: false,
      theme: ScreenshotBrainTheme.light,
      darkTheme: ScreenshotBrainTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
