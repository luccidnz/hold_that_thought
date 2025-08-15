import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/data/thought_repository.dart';
import 'package:hold_that_thought/models/thought.dart';

// 1. Provider for the repository implementation
final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  // In a real app, you might switch this out with a different implementation
  // for testing or other backends.
  return HiveThoughtRepository();
});

// 2. StreamProvider to watch all thoughts
final thoughtsProvider = StreamProvider<List<Thought>>((ref) {
  final repository = ref.watch(thoughtRepositoryProvider);
  // The stream will be listened to by the UI.
  // It will automatically re-evaluate if the repository changes.
  return repository.watchAll();
});
