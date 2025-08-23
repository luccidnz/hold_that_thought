import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/routing/deeplink_controller.dart';
import 'package:hold_that_thought/routing/deeplink_source.dart';
import 'package:hold_that_thought/routing/navigation_service.dart';
import 'package:mockito/mockito.dart' as m;
import 'package:mockito/annotations.dart';

import 'deeplink_controller_test.mocks.dart';

class FakeDeepLinkSource implements DeepLinkSource {
  final Uri? _initial;
  final _streamController = StreamController<Uri?>();

  FakeDeepLinkSource({Uri? initial}) : _initial = initial;

  @override
  Future<Uri?> getInitialUri() async => _initial;

  @override
  Stream<Uri?> get uriStream => _streamController.stream;

  void addLink(Uri uri) {
    _streamController.add(uri);
  }

  void dispose() {
    _streamController.close();
  }
}

@GenerateMocks([NavigationService])
void main() {
  group('DeepLinkController', () {
    late FakeDeepLinkSource fakeSource;
    late MockNavigationService mockNav;
    late ProviderContainer container;

    setUp(() {
      fakeSource = FakeDeepLinkSource();
      mockNav = MockNavigationService();
    });

    tearDown(() {
      fakeSource.dispose();
      container.dispose();
    });

    test('routes valid initial note link to detail', () async {
      fakeSource =
          FakeDeepLinkSource(initial: Uri.parse('myapp://note/abc123'));
      container = ProviderContainer(overrides: [
        deepLinkSourceProvider.overrideWithValue(fakeSource),
        navigationServiceProvider.overrideWithValue(mockNav),
      ]);

      await container.read(deepLinkControllerProvider.future);

      m.verify(mockNav.go('/note/abc123')).called(1);
    });

    test('routes valid subsequent note link to detail', () async {
      container = ProviderContainer(overrides: [
        deepLinkSourceProvider.overrideWithValue(fakeSource),
        navigationServiceProvider.overrideWithValue(mockNav),
      ]);
      await container.read(deepLinkControllerProvider.future);

      fakeSource.addLink(Uri.parse('myapp://note/xyz456'));
      await Future.delayed(const Duration(milliseconds: 10));

      m.verify(mockNav.go('/note/xyz456')).called(1);
    });

    test('ignores invalid link with whitespace', () async {
      fakeSource = FakeDeepLinkSource(initial: Uri.parse('myapp://note/   '));
      container = ProviderContainer(overrides: [
        deepLinkSourceProvider.overrideWithValue(fakeSource),
        navigationServiceProvider.overrideWithValue(mockNav),
      ]);
      await container.read(deepLinkControllerProvider.future);

      m.verifyNever(mockNav.go(m.any));
    });

    test('handles no initial link safely', () async {
      container = ProviderContainer(overrides: [
        deepLinkSourceProvider.overrideWithValue(fakeSource),
        navigationServiceProvider.overrideWithValue(mockNav),
      ]);
      await container.read(deepLinkControllerProvider.future);

      m.verifyNever(mockNav.go(m.any));
    });
  });
}
