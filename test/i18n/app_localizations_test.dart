import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Unit test for the controller logic
  group('LocaleController', () {
    test('setLocale saves the language code to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose); // Ensure the container is disposed.
      final controller = container.read(localeProvider.notifier);

      await controller.setLocale(const Locale('mi'));
      expect(container.read(localeProvider)?.languageCode, 'mi');

      // Verify it was saved to prefs
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'mi');
    });

    test('setLocale(null) removes the value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'locale': 'mi'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(localeProvider.notifier);

      await controller.setLocale(null);
      expect(container.read(localeProvider), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), isNull);
    });
  });
}
