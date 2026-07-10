import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _kThemeKey = 'theme_mode';
  static const _kLocaleKey =
      'locale_code'; // Key for saving language preference

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en'); // Default to English [12]

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Theme Mode
      _themeMode = switch (prefs.getString(_kThemeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      // Load Locale [11]
      final localeCode = prefs.getString(_kLocaleKey);
      _locale = localeCode == 'am' ? const Locale('am') : const Locale('en');
    } catch (e) {
      debugPrint('[ThemeProvider] Error loading preferences: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });
    } catch (e) {
      debugPrint('[ThemeProvider] Error saving theme: $e');
    }
  }

  // New: Method to update and persist the language [11, 12]
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, locale.languageCode);
    } catch (e) {
      debugPrint('[ThemeProvider] Error saving locale: $e');
    }
  }
}
