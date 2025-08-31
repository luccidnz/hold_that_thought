import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/hive_boot.dart';
import 'state/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final box = await openThoughtsBoxRobust();
  runApp(
    ProviderScope(
      overrides: [ thoughtsBoxProvider.overrideWithValue(box) ],
      child: const HoldThatThoughtApp(),
    ),
  );
}