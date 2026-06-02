import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
  static const String _themeKey = 'app_theme_mode';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);
    if (isDark == true) {
      themeNotifier.value = ThemeMode.dark;
    } else if (isDark == false) {
      themeNotifier.value = ThemeMode.light;
    }
  }

  static Future<void> toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}
