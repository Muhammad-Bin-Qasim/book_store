import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'core/utils/error_handler.dart';
import 'firebase_options.dart';
import 'widgets/global_error_fallback.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      _reportUnhandledError(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _reportUnhandledError(error, stackTrace);
      return true;
    };
    ErrorWidget.builder = (_) => const GlobalErrorFallback();

    final themeController = await ThemeController.load();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(BookStoreApp(themeController: themeController));
    } catch (error, stackTrace) {
      final startupThemeMode = themeController.themeMode;
      themeController.dispose();
      _reportUnhandledError(error, stackTrace);
      runApp(_StartupErrorApp(themeMode: startupThemeMode));
    }
  }, _reportUnhandledError);
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  debugPrint(ErrorHandler.message(error));
  debugPrintStack(stackTrace: stackTrace);
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    AppStrings.startupError,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
