import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hold_that_thought/theme/app_theme.dart';

class ThemeState {
  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.accent = Accent.blue,
  });

  final ThemeMode themeMode;
  final Accent accent;

  ThemeState copyWith({
    ThemeMode? themeMode,
    Accent? accent,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
    );
  }
}

class ThemeController extends StateNotifier<ThemeState> {
  ThemeController() : super(const ThemeState()) {
    _loadTheme();
  }

  static const String _themeModeKey = 'theme.mode';
  static const String _accentColorKey = 'theme.accent';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    final accentColorString = prefs.getString(_accentColorKey);

    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.system,
    );

    final accentColor = Accent.values.firstWhere(
      (e) => e.toString() == 'Accent.$accentColorString',
      orElse: () => Accent.blue,
    );

    state = ThemeState(themeMode: themeMode, accent: accentColor);
  }

  Future<void> setMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.toString().split('.').last);
    state = state.copyWith(themeMode: themeMode);
  }

  Future<void> setAccent(Accent accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, accent.toString().split('.').last);
    state = state.copyWith(accent: accent);
  }
}

final themeProvider = StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController();
});
