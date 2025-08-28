import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/routing/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hold_that_thought/models/thought.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ThoughtAdapter());
  runApp(const ProviderScope(child: HoldThatThoughtApp()));
}

class HoldThatThoughtApp extends ConsumerWidget {
  const HoldThatThoughtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Hold That Thought',
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      routerConfig: router,
    );
  }
}
