import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/repository/thought_repository.dart';
import '../models/thought.dart';

final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  return ThoughtRepository();
});

/// Live list of thoughts (watch Hive by reloading on writes you control).
final thoughtsListProvider = FutureProvider<List<Thought>>((ref) async {
  final repo = ref.read(thoughtRepositoryProvider);
  return repo.getAll();
});

/// Simple sync counters for UI badges/diagnostics.
class SyncStats {
  final int total;
  final int pending;
  const SyncStats(this.total, this.pending);
}

final syncStatsProvider = FutureProvider<SyncStats>((ref) async {
  final repo = ref.read(thoughtRepositoryProvider);
  final all = await repo.getAll();
  final pending = all.where((t) => t.remoteId == null).length;
  return SyncStats(all.length, pending);
});
