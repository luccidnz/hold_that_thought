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
          theme: AppTheme.lightFor(Accent.blue),
          darkTheme: AppTheme.darkFor(Accent.blue),
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
    final container = ProviderContainer();
    final themeController = container.read(themeProvider.notifier);
    await themeController.setMode(ThemeMode.dark);
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp(
          theme: AppTheme.lightFor(Accent.blue),
          darkTheme: AppTheme.darkFor(Accent.blue),
          themeMode: ThemeMode.dark,
          home: const SettingsScreen(),
        ),
      ),
    );

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen_dark.png'),
    );
  });
}
