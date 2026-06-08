import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'theme_extensions.dart';

class ScreenshotBrainTheme {
  ScreenshotBrainTheme._();

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        background: AppColors.background,
        surface: AppColors.surface,
        card: AppColors.card,
        elevated: AppColors.elevated,
        border: AppColors.border,
        borderLight: AppColors.borderLight,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        success: AppColors.success,
        successContainer: AppColors.successContainer,
        warning: AppColors.warning,
        warningContainer: AppColors.warningContainer,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        textTertiary: AppColors.textTertiary,
        textInverse: AppColors.textInverse,
      );

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        card: AppColors.lightCard,
        elevated: AppColors.lightElevated,
        border: AppColors.lightBorder,
        borderLight: AppColors.lightBorderLight,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightBackground,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: const Color(0xFF003544),
        secondary: AppColors.lightSecondary,
        secondaryContainer: AppColors.lightSecondaryContainer,
        onSecondaryContainer: const Color(0xFF3B0764),
        success: AppColors.lightSuccess,
        successContainer: const Color(0xFFD1FAE5),
        warning: AppColors.lightWarning,
        warningContainer: const Color(0xFFFEF3C7),
        error: AppColors.lightError,
        errorContainer: const Color(0xFFFEE2E2),
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        textTertiary: AppColors.lightTextTertiary,
        textInverse: AppColors.lightBackground,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color card,
    required Color elevated,
    required Color border,
    required Color borderLight,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color secondary,
    required Color secondaryContainer,
    required Color onSecondaryContainer,
    required Color success,
    required Color successContainer,
    required Color warning,
    required Color warningContainer,
    required Color error,
    required Color errorContainer,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color textInverse,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: textPrimary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: const Color(0xFF38BDF8),
      onTertiary: const Color(0xFF0F172A),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: errorContainer,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: card,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: borderLight,
      shadow: Colors.black,
      inverseSurface: elevated,
      onInverseSurface: textPrimary,
      inversePrimary: primary.withValues(alpha: 0.9),
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        actionsIconTheme: IconThemeData(color: textSecondary, size: 22),
        iconTheme: IconThemeData(color: textSecondary, size: 22),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderLight, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1),
        ),
        hintStyle: TextStyle(color: textTertiary, fontSize: 15),
        labelStyle: TextStyle(color: textSecondary, fontSize: 15),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: onPrimary,
          ),
        ),
      ),

      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: onPrimary,
          ),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Icon button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
        modalElevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: elevated,
        selectedColor: primaryContainer,
        disabledColor: elevated,
        labelStyle: TextStyle(color: textSecondary, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: textSecondary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: borderLight,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryContainer;
          return borderLight;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: BorderSide(color: textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textTertiary;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: borderLight,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        valueIndicatorColor: elevated,
        valueIndicatorTextStyle: TextStyle(color: textPrimary, fontSize: 13),
      ),

      // Text
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.3,
          height: 1.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textTertiary,
          letterSpacing: 0.5,
          height: 1.3,
        ),
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textTertiary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
        ),
      ),

      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onPrimary,
          letterSpacing: -0.2,
        ),
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.black38,
      ),

      // Menu
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(elevated),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: -0.1,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: textSecondary,
        textColor: textPrimary,
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
          }
          return TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textTertiary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 24, color: primary);
          }
          return IconThemeData(size: 24, color: textTertiary);
        }),
      ),

      // Extensions
      extensions: [
        ScreenshotBrainThemeExtension(
          background: background,
          surface: surface,
          card: card,
          elevated: elevated,
          border: border,
          borderLight: borderLight,
          success: success,
          successContainer: successContainer,
          warning: warning,
          warningContainer: warningContainer,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textTertiary: textTertiary,
          textInverse: textInverse,
          primaryDim: brightness == Brightness.dark
              ? AppColors.primaryDim
              : const Color(0xFF00BCD4),
          secondaryDim: brightness == Brightness.dark
              ? AppColors.secondaryDim
              : const Color(0xFF7C3AED),
          shimmerBase: brightness == Brightness.dark
              ? AppColors.shimmerBase
              : const Color(0xFFE2E8F0),
          shimmerHighlight: brightness == Brightness.dark
              ? AppColors.shimmerHighlight
              : const Color(0xFFF1F5F9),
        ),
      ],
    );
  }
}
