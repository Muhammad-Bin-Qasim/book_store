import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:book_store/core/app_constants.dart';
import 'package:book_store/core/app_theme.dart';
import 'package:book_store/core/theme_controller.dart';
import 'package:book_store/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows the Book Store brand', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.splashTagline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  test('ThemeController persists and restores the selected mode', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final firstController = await ThemeController.load();
    expect(firstController.mode, AppThemeMode.system);
    await firstController.setMode(AppThemeMode.dark);
    firstController.dispose();

    final restoredController = await ThemeController.load();
    addTearDown(restoredController.dispose);
    expect(restoredController.mode, AppThemeMode.dark);
    expect(restoredController.themeMode, ThemeMode.dark);
  });

  test('Theme uses locally bundled fonts and Urdu fallbacks', () {
    final theme = AppTheme.light;
    expect(theme.textTheme.displayLarge?.fontFamily, 'Fraunces');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Fraunces');
    expect(theme.textTheme.titleMedium?.fontFamily, 'PlusJakartaSans');
    expect(theme.textTheme.bodySmall?.fontSize, 14);
    expect(
      theme.textTheme.bodyMedium?.fontFamilyFallback,
      contains('Noto Nastaliq Urdu'),
    );

    final priceStyle = AppTheme.priceTextStyle();
    expect(priceStyle.fontFamily, 'PlusJakartaSans');
    expect(priceStyle.fontWeight, FontWeight.w800);
    expect(
      priceStyle.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('Latin and Urdu text fit at 360dp and 1.3x text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          );
        },
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Stories worth returning to',
                  style: AppTheme.light.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text('کتاب، علم اور کہانی'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(AppStrings.total)),
                    Text('Rs 12,345.67', style: AppTheme.priceTextStyle()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
