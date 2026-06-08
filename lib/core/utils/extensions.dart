import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String get formatted => DateFormat('dd MMM yyyy').format(this);
  String get formattedWithTime => DateFormat('dd MMM yyyy HH:mm').format(this);
  String get monthYear => DateFormat('MMM yyyy').format(this);
}

extension StringExtension on String {
  String get capitalized => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get truncated => length > 100 ? '${substring(0, 100)}...' : this;
  bool get isEmail => contains('@');
  bool get isPhoneNumber =>
      RegExp(r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]*$').hasMatch(this);
}

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
