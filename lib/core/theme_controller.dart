import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeController extends ChangeNotifier {
  ThemeController._(this._preferences, this._mode);

  static const String _preferenceKey = 'app_theme_mode';

  SharedPreferences? _preferences;
  AppThemeMode _mode;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode => switch (_mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  /// Restores the saved preference before the app's first frame.
  /// Storage failures gracefully fall back to the system setting.
  static Future<ThemeController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedMode = preferences.getString(_preferenceKey);
      final mode = AppThemeMode.values.firstWhere(
        (candidate) => candidate.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
      return ThemeController._(preferences, mode);
    } catch (_) {
      return ThemeController._(null, AppThemeMode.system);
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    try {
      _preferences ??= await SharedPreferences.getInstance();
      await _preferences?.setString(_preferenceKey, mode.name);
    } catch (_) {
      // Keep the in-memory choice even when persistence is unavailable.
    }
  }
}
