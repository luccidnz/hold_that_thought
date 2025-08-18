import 'package:hold_that_thought/flavor.dart';
import 'package:hold_that_thought/main.dart' as app;

Future<void> main() async {
  await app.run(flavor: Flavor.dev);
}
