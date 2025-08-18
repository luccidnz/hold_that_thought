import 'package:flutter/material.dart';

enum AccentColor {
  blue,
  red,
  green,
  orange,
  purple,
  pink,
}

extension AccentColorExtension on AccentColor {
  Color get color {
    switch (this) {
      case AccentColor.blue:
        return Colors.blue;
      case AccentColor.red:
        return Colors.red;
      case AccentColor.green:
        return Colors.green;
      case AccentColor.orange:
        return Colors.orange;
      case AccentColor.purple:
        return Colors.purple;
      case AccentColor.pink:
        return Colors.pink;
    }
  }
}

class AppTheme {
  static ThemeData getTheme(AccentColor accentColor, Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor.color,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }
}
