import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/sync/sync_service.dart';

class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(notesRepositoryProvider).syncStatus;

    return StreamBuilder<SyncStatus>(
      stream: syncStatus,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          switch (snapshot.data!) {
            case SyncStatus.syncing:
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            case SyncStatus.ok:
              return const Icon(Icons.cloud_done);
            case SyncStatus.error:
              return const Icon(Icons.cloud_off, color: Colors.red);
            case SyncStatus.idle:
              return const Icon(Icons.cloud_queue);
          }
        }
        return const Icon(Icons.cloud_queue);
      },
    );
  }
}
