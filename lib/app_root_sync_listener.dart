import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/app.dart';
import 'package:hold_that_thought/state/sync_events.dart';
import 'package:hold_that_thought/state/sync_providers.dart';

class RootSyncListener extends ConsumerWidget {
  final Widget child;
  const RootSyncListener({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to single-shot events
    ref.listen<SyncEvent?>(syncEventBusProvider, (prev, event) {
      if (event == null) return;

      String text;
      SnackBarAction? action;

      switch (event.type) {
        case SyncEventType.queueStarted:
          text = 'Uploading pending thoughts…';
          break;
        case SyncEventType.itemUploadStarted:
          text = 'Uploading…';
          break;
        case SyncEventType.itemUploadSucceeded:
          text = 'Upload complete';
          break;
        case SyncEventType.itemUploadFailed:
          text = event.message ?? 'Upload failed';
          action = SnackBarAction(
            label: 'Retry',
            onPressed: () {
              // trigger retry for this thought id
              if (event.thoughtId != null) {
                ref.read(syncServiceProvider).retry(event.thoughtId!);
              }
            },
          );
          break;
        case SyncEventType.bulkCompleted:
          text = 'Cloud backup finished';
          break;
      }

      // Only show milestone SnackBars; progress stays in UI.
      final bar = SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        action: action,
        duration: const Duration(seconds: 3),
      );
      rootScaffoldMessengerKey.currentState?.showSnackBar(bar);
    });

    return child;
  }
}
