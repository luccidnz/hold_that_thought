import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hold_that_thought/app.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/providers/thought_providers.dart';

Future<void> main() async {
  // Ensure that Flutter bindings are initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register the adapter for the Thought model
  // This line will cause an error until build_runner is run
  Hive.registerAdapter(ThoughtAdapter());

  // Initialize the repository. This will open the Hive box.
  // We do this here to ensure the box is open before the app starts.
  final container = ProviderContainer();
  await container.read(thoughtRepositoryProvider).init();

  runApp(
    // ProviderScope stores the state of our providers.
    // We pass the container we created so it holds the initialized repository.
    UncontrolledProviderScope(
      container: container,
      child: const HoldThatThoughtApp(),
    ),
  );
}