import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hold_that_thought/theme/app_theme.dart';

class ThemeState {
  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.accentColor = AccentColor.blue,
  });

  final ThemeMode themeMode;
  final AccentColor accentColor;

  ThemeState copyWith({
    ThemeMode? themeMode,
    AccentColor? accentColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeController extends StateNotifier<ThemeState> {
  ThemeController() : super(const ThemeState()) {
    _loadTheme();
  }

  static const String _themeModeKey = 'themeMode';
  static const String _accentColorKey = 'accentColor';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    final accentColorString = prefs.getString(_accentColorKey);

    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.system,
    );

    final accentColor = AccentColor.values.firstWhere(
      (e) => e.toString() == 'AccentColor.$accentColorString',
      orElse: () => AccentColor.blue,
    );

    state = ThemeState(themeMode: themeMode, accentColor: accentColor);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.toString().split('.').last);
    state = state.copyWith(themeMode: themeMode);
  }

  Future<void> setAccentColor(AccentColor accentColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, accentColor.toString().split('.').last);
    state = state.copyWith(accentColor: accentColor);
  }
}

final themeProvider = StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController();
});
