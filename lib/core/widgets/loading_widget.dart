import 'package:flutter/material.dart';
import '../components/sb_loading.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return SbLoading(message: message);
  }
}
