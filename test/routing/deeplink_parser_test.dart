import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/routing/deeplink_controller.dart';

void main() {
  group('DeepLinkNavigator', () {
    late DeepLinkNavigator navigator;

    setUp(() {
      navigator = DeepLinkNavigator();
    });

    test('parses /new route', () {
      final uri = Uri.parse('app://new');
      final action = navigator.parse(uri);
      expect(action, isA<NewThoughtAction>());
    });

    test('parses /t/<id> route', () {
      final uri = Uri.parse('app://t/some-id');
      final action = navigator.parse(uri);
      expect(action, isA<ViewThoughtAction>());
      expect((action as ViewThoughtAction).id, 'some-id');
    });

    test('returns null for invalid route', () {
      final uri = Uri.parse('app://invalid/route');
      final action = navigator.parse(uri);
      expect(action, isNull);
    });

    test('returns null for empty route', () {
      final uri = Uri.parse('app://');
      final action = navigator.parse(uri);
      expect(action, isNull);
    });
  });
}
