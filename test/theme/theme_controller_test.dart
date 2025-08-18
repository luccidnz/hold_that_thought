import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/theme/app_theme.dart';
import 'package:hold_that_thought/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeController', () {
    test('loads theme from shared preferences', () async {
      SharedPreferences.setMockInitialValues({
        'themeMode': 'dark',
        'accentColor': 'red',
      });
      final controller = ThemeController();
      await Future.delayed(Duration.zero); // allow async load to complete
      expect(controller.debugState.themeMode, ThemeMode.dark);
      expect(controller.debugState.accentColor, AccentColor.red);
    });

    test('saves theme mode to shared preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeController();
      await controller.setThemeMode(ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'light');
    });

    test('saves accent color to shared preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeController();
      await controller.setAccentColor(AccentColor.purple);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('accentColor'), 'purple');
    });
  });
}
