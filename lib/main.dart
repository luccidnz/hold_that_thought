import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/flavor.dart';
import 'package:hold_that_thought/flavor_banner.dart';
import 'package:hold_that_thought/routing/app_router.dart';
import 'package:hold_that_thought/theme/app_theme.dart';
import 'package:hold_that_thought/theme/theme_controller.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hold_that_thought/storage/hive_boxes.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:uuid/uuid.dart';

final flavorProvider = Provider<Flavor>((ref) => throw UnimplementedError());

Future<void> run({required Flavor flavor}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(ChangeTypeAdapter());
  Hive.registerAdapter(NoteChangeAdapter());
  final notesBox = await Hive.openBox<Note>(HiveBoxes.notes);
  await Hive.openBox<NoteChange>(HiveBoxes.pendingOps);

  if (kDebugMode && notesBox.isEmpty) {
    final now = DateTime.now();
    final uuid = Uuid();
    notesBox.put(
      '123',
      Note(
        id: '123',
        title: 'Test Note 1',
        body: 'This is a test note about Flutter.',
        createdAt: now,
        updatedAt: now,
        isPinned: false,
        tags: ['work', 'flutter'],
      ),
    );
    notesBox.put(
      '456',
      Note(
        id: '456',
        title: 'Test Note 2',
        body: 'This is another test note about personal stuff.',
        createdAt: now,
        updatedAt: now,
        isPinned: true,
        tags: ['personal'],
      ),
    );
  }

  setPathUrlStrategy();
  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
      ],
      child: const HoldThatThoughtApp(),
    ),
  );
}

class HoldThatThoughtApp extends ConsumerWidget {
  const HoldThatThoughtApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);
    final flavor = ref.watch(flavorProvider);

    return Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor: mediaQuery.textScaleFactor.clamp(0.8, 2.0),
          ),
          child: FlavorBanner(
            child: MaterialApp.router(
              title: 'Hold That Thought',
              theme: AppTheme.lightFor(themeState.accent),
            darkTheme: AppTheme.darkFor(themeState.accent),
            themeMode: themeState.themeMode,
            routerConfig: router,
          ),
        );
      },
    );
  }
}