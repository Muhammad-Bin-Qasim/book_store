import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_constants.dart';

class AppTheme {
  AppTheme._();

  static const String _bodyFontFamily = 'PlusJakartaSans';
  static const String _headingFontFamily = 'Fraunces';
  static const List<String> _fontFamilyFallback = [
    'Noto Nastaliq Urdu',
    'Noto Naskh Arabic',
    'Noto Sans Arabic',
    'Geeza Pro',
    'Arial',
  ];

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static SystemUiOverlayStyle systemUiOverlayStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.colorScheme.surface,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
      systemNavigationBarContrastEnforced: true,
    );
  }

  static TextStyle priceTextStyle({TextStyle? baseStyle}) {
    return (baseStyle ?? const TextStyle(fontSize: 16)).copyWith(
      fontFamily: _bodyFontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.emerald,
          brightness: brightness,
          surface: isDark ? const Color(0xFF111D18) : AppColors.cream,
          primary: isDark ? const Color(0xFF9BCBB0) : AppColors.emerald,
          onPrimary: isDark ? AppColors.ink : AppColors.onDarkAccent,
          secondary: AppColors.amber,
          onSecondary: AppColors.ink,
          tertiary: isDark ? const Color(0xFFFFD17A) : const Color(0xFF765000),
          onTertiary: isDark ? AppColors.ink : AppColors.onDarkAccent,
          error: isDark ? const Color(0xFFFF9B8D) : const Color(0xFFB9382B),
        ).copyWith(
          onSurface: isDark ? AppColors.cream : AppColors.ink,
          onSurfaceVariant: isDark
              ? const Color(0xFFC4D0C8)
              : const Color(0xFF45534B),
          surfaceContainerHighest: isDark
              ? const Color(0xFF25352D)
              : const Color(0xFFF1E9D9),
          outline: isDark ? const Color(0xFF819187) : const Color(0xFF78877D),
          outlineVariant: isDark
              ? const Color(0xFF53665A)
              : const Color(0xFFB8C3B9),
        );
    final baseText = ThemeData(
      brightness: brightness,
      fontFamily: _bodyFontFamily,
      fontFamilyFallback: _fontFamilyFallback,
    ).textTheme;

    TextStyle headingStyle(
      TextStyle? style, {
      required double height,
      double? letterSpacing,
    }) {
      return (style ?? const TextStyle()).copyWith(
        fontFamily: _headingFontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w700,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    final textTheme = baseText.copyWith(
      displayLarge: headingStyle(
        baseText.displayLarge,
        height: 1.1,
        letterSpacing: -1.3,
      ),
      displayMedium: headingStyle(
        baseText.displayMedium,
        height: 1.1,
        letterSpacing: -0.9,
      ),
      displaySmall: headingStyle(
        baseText.displaySmall,
        height: 1.12,
        letterSpacing: -0.5,
      ),
      headlineLarge: headingStyle(
        baseText.headlineLarge,
        height: 1.12,
        letterSpacing: -0.4,
      ),
      headlineMedium: headingStyle(
        baseText.headlineMedium,
        height: 1.14,
        letterSpacing: -0.2,
      ),
      headlineSmall: headingStyle(
        baseText.headlineSmall,
        height: 1.16,
        letterSpacing: -0.1,
      ),
      titleLarge: headingStyle(
        baseText.titleLarge,
        height: 1.18,
        letterSpacing: -0.1,
      ),
      bodySmall: baseText.bodySmall?.copyWith(fontSize: 14),
      bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 14),
    );

    final overlayStyle = systemUiOverlayStyle(
      ThemeData(brightness: brightness, colorScheme: scheme),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: _bodyFontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: TextStyle(
          fontFamily: _headingFontFamily,
          fontFamilyFallback: _fontFamilyFallback,
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF192821) : scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: .55)
            : scheme.surface.withValues(alpha: .88),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: scheme.outlineVariant),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
    );
  }
}
