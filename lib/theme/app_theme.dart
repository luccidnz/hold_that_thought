import 'package:flutter/material.dart';

enum Accent {
  blue,
  green,
  teal,
  purple,
  orange,
  red,
}

extension AccentExtension on Accent {
  Color get color {
    switch (this) {
      case Accent.blue:
        return Colors.blue;
      case Accent.green:
        return Colors.green;
      case Accent.teal:
        return Colors.teal;
      case Accent.purple:
        return Colors.purple;
      case Accent.orange:
        return Colors.orange;
      case Accent.red:
        return Colors.red;
    }
  }
}

class AppTheme {
  static ThemeData lightFor(Accent accent) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent.color,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData darkFor(Accent accent) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent.color,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
