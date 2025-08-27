import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/data/hive_thought_repository.dart';
import 'package:hold_that_thought/data/thought_repository.dart';

final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  final repo = HiveThoughtRepository();
  repo.init();
  return repo;
});
