import 'package:flutter/material.dart';
import '../design/tokens.dart';
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
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textInverse: AppColors.textInverse,
    primaryDim: AppColors.primaryDim,
    secondaryDim: AppColors.secondaryDim,
    shimmerBase: AppColors.shimmerBase,
    shimmerHighlight: AppColors.shimmerHighlight,
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
    onPrimaryContainer: AppColors.lightOnPrimaryContainer,
    secondary: AppColors.lightSecondary,
    onSecondary: AppColors.lightOnSecondary,
    secondaryContainer: AppColors.lightSecondaryContainer,
    onSecondaryContainer: AppColors.lightOnSecondaryContainer,
    tertiary: AppColors.lightTertiary,
    onTertiary: AppColors.lightOnTertiary,
    success: AppColors.lightSuccess,
    successContainer: AppColors.lightSuccessContainer,
    warning: AppColors.lightWarning,
    warningContainer: AppColors.lightWarningContainer,
    error: AppColors.lightError,
    onError: AppColors.lightOnError,
    errorContainer: AppColors.lightErrorContainer,
    onErrorContainer: AppColors.lightOnErrorContainer,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    textInverse: AppColors.lightBackground,
    primaryDim: AppColors.lightPrimaryDim,
    secondaryDim: AppColors.lightSecondaryDim,
    shimmerBase: AppColors.lightShimmerBase,
    shimmerHighlight: AppColors.lightShimmerHighlight,
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
    required Color onSecondary,
    required Color secondaryContainer,
    required Color onSecondaryContainer,
    required Color tertiary,
    required Color onTertiary,
    required Color success,
    required Color successContainer,
    required Color warning,
    required Color warningContainer,
    required Color error,
    required Color onError,
    required Color errorContainer,
    required Color onErrorContainer,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color textInverse,
    required Color primaryDim,
    required Color secondaryDim,
    required Color shimmerBase,
    required Color shimmerHighlight,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      error: error,
      // Per-mode ink from AppColors: white on the dark-mode error is 4.01:1
      // and misses AA, so the hardwired Colors.white here was a dark-only bug.
      onError: onError,
      errorContainer: errorContainer,
      // Previously this was errorContainer itself, which made error
      // foreground text invisible on its own container.
      onErrorContainer: onErrorContainer,
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
          borderRadius: BorderRadius.circular(SBRadius.xl),
          side: BorderSide(color: borderLight, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SBSpacing.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.lg),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.lg),
          borderSide: BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.lg),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SBRadius.lg),
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
          padding: const EdgeInsets.symmetric(
            horizontal: SBSpacing.xxl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.lg),
          ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: SBSpacing.xxl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.lg),
          ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: SBSpacing.xxl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.lg),
          ),
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
          padding: const EdgeInsets.all(SBSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.md),
          ),
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SBRadius.xxl),
          ),
        ),
        elevation: 0,
        modalElevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SBRadius.xxl),
        ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: SBSpacing.md,
          vertical: 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SBRadius.sm),
        ),
        side: BorderSide.none,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SBRadius.lg),
        ),
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
          fontSize: SBTypography.displayLarge,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: SBTypography.displayMedium,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        displaySmall: TextStyle(
          fontSize: SBTypography.displaySmall,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: SBTypography.headlineLarge,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: SBTypography.headlineMedium,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: SBTypography.headlineSmall,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: SBTypography.titleLarge,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: SBTypography.titleMedium,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          fontSize: SBTypography.titleSmall,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: SBTypography.bodyLarge,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: SBTypography.bodyMedium,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: SBTypography.bodySmall,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: SBTypography.labelLarge,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        labelMedium: TextStyle(
          fontSize: SBTypography.labelMedium,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.3,
          height: 1.3,
        ),
        labelSmall: TextStyle(
          fontSize: SBTypography.labelSmall,
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
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SBRadius.xl),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SBRadius.lg),
        ),
        elevation: 4,
        shadowColor: Colors.black38,
      ),

      // Menu
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(elevated),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SBRadius.lg),
            ),
          ),
        ),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SBSpacing.lg,
          vertical: SBSpacing.xs,
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SBRadius.lg),
        ),
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
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textTertiary,
          );
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
          primaryDim: primaryDim,
          secondaryDim: secondaryDim,
          shimmerBase: shimmerBase,
          shimmerHighlight: shimmerHighlight,
        ),
      ],
    );
  }
}
