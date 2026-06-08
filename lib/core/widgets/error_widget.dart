import 'package:flutter/material.dart';
import '../components/sb_error_state.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SbErrorState(message: message, onRetry: onRetry);
  }
}
