import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repos/thought_repo.dart';
import '../models/thought.dart';

/// Single instance of the repository for the whole app.
/// (In main.dart you already init it with container.read(...).init())
final thoughtRepositoryProvider = Provider<ThoughtRepo>((ref) => ThoughtRepo());

/// Live stream of thoughts (pinned first, newest first).
final thoughtsProvider = StreamProvider<List<Thought>>((ref) {
  final repo = ref.watch(thoughtRepositoryProvider);
  return repo.watchAll(); // repo emits an initial snapshot + updates
});