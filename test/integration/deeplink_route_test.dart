import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:hold_that_thought/flavor.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hold_that_thought/main.dart' as app;
import 'package:hold_that_thought/routing/deeplink_source.dart';

class TestDeepLinkSource implements DeepLinkSource {
  final _controller = Stream<Uri?>.multi((c) {});
  @override
  Stream<Uri?> get uriStream => _controller;
  @override
  Future<Uri?> getInitialUri() async => Uri.parse('myapp://note/123');
  void dispose() {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  ft.testWidgets('Handles /note/:id deep link', (tester) async {
    final source = TestDeepLinkSource();
    final container = ProviderContainer(
      overrides: [
        deepLinkSourceProvider.overrideWithValue(source),
      ],
    );

    await app.run(flavor: Flavor.dev, container: container);
    await tester.pumpAndSettle();
    // Adapt the assertion to what the Note screen renders.
    ft.expect(ft.find.textContaining('123'), ft.findsWidgets);
  });
}
