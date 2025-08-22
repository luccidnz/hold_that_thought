import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/routing/app_router.dart';
import 'package:hold_that_thought/routing/deeplink_controller.dart';
import 'package:hold_that_thought/routing/deeplink_source.dart';
import 'package:hold_that_thought/routing/navigation_service.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:mockito/annotations.dart';

import 'deeplink_controller_test.mocks.dart';

@GenerateMocks([DeepLinkSource, NavigationService])
void main() {
  group('DeepLinkController', () {
    late MockDeepLinkSource mockSource;
    late MockNavigationService mockRouter;
    late ProviderContainer container;

    setUp(() {
      mockSource = MockDeepLinkSource();
      mockRouter = MockNavigationService();
      // The controller is NOT created here. It will be created on-demand
      // by Riverpod when the test accesses the provider.
    });

    test('initial link is processed on startup', () async {
      const initialLink = 'app://note/123';
      mockito
          .when(mockSource.getInitialLink())
          .thenAnswer((_) async => initialLink);
      mockito.when(mockSource.linkStream).thenAnswer((_) => Stream.empty());

      // Create the container, which will instantiate the controller
      container = ProviderContainer(overrides: [
        deepLinkSourceProvider.overrideWithValue(mockSource),
        navigationServiceProvider.overrideWithValue(mockRouter),
      ]);

      // The controller is created asynchronously. We need to wait for it.
      await container.read(deepLinkControllerProvider.future);

      // Now we can verify that the navigation method was called.
      mockito.verify(mockRouter.go('/note/123')).called(1);
    });

    test('subsequent links are processed', () async {
      final linkStream = Stream.fromIterable(['app://note/456', 'app://note/789']);
      mockito.when(mockSource.getInitialLink()).thenAnswer((_) async => null);
      mockito.when(mockSource.linkStream).thenAnswer((_) => linkStream);

      container = ProviderContainer(overrides: [
        deepLinkSourceProvider.overrideWithValue(mockSource),
        navigationServiceProvider.overrideWithValue(mockRouter),
      ]);
      addTearDown(container.dispose);

      // The controller is created asynchronously.
      await container.read(deepLinkControllerProvider.future);

      // Wait for stream events to be processed.
      await Future.delayed(const Duration(milliseconds: 100));

      mockito.verify(mockRouter.go('/note/456')).called(1);
      mockito.verify(mockRouter.go('/note/789')).called(1);
    });

    test('null and empty links are ignored', () async {
      final linkStream = Stream.fromIterable([null, '']);
      mockito.when(mockSource.getInitialLink()).thenAnswer((_) async => null);
      mockito.when(mockSource.linkStream).thenAnswer((_) => linkStream);

      container = ProviderContainer(overrides: [
        deepLinkSourceProvider.overrideWithValue(mockSource),
        navigationServiceProvider.overrideWithValue(mockRouter),
      ]);
      addTearDown(container.dispose);

      await container.read(deepLinkControllerProvider.future);
      await Future.delayed(const Duration(milliseconds: 100));

      mockito.verifyNever(mockRouter.go(mockito.any));
    });
  });
}
