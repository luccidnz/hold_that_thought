import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/settings/settings_screen.dart';
import 'package:hold_that_thought/theme/app_theme.dart';
import 'package:hold_that_thought/theme/theme_controller.dart';

void main() {
  testWidgets('SettingsScreen golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.getTheme(AccentColor.blue, Brightness.light),
          darkTheme: AppTheme.getTheme(AccentColor.blue, Brightness.dark),
          home: const SettingsScreen(),
        ),
      ),
    );

    // Test in light mode
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen_light.png'),
    );

    // Test in dark mode
    final themeController = ProviderContainer().read(themeProvider.notifier);
    themeController.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen_dark.png'),
    );
  });
}
