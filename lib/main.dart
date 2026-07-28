import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/database_service.dart';

// 1. App entry point
void main() async {
  // 2. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  // 3. Initialize the database service
  await DatabaseService.init();
  // 4. Run the application
  runApp(const ProviderScope(child: ScreenshotBrainApp()));
}
// 5. End of main
