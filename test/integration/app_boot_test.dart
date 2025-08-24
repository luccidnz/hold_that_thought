import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:integration_test/integration_test.dart';
import 'package:hold_that_thought/main.dart' as app;
import 'package:hold_that_thought/main.dart';
import 'package:hold_that_thought/flavor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  ft.testWidgets('App boots and shows first frame', (tester) async {
    await app.run(flavor: Flavor.dev);
    await tester.pumpAndSettle();
    // Replace `App` with the top-level widget class if named differently.
    ft.expect(ft.find.byType(HoldThatThoughtApp), ft.findsOneWidget);
  });
}
