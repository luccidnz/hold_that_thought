import 'package:flutter/material.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/state/encrypted_repo_providers.dart';

/// A widget that displays an encryption badge for a thought
class EncryptionBadge extends ConsumerWidget {
  final Thought thought;

  const EncryptionBadge({Key? key, required this.thought}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(encryptionBadgeProvider(thought));

    if (badge == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade700, width: 1),
      ),
      child: Text(
        badge,
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
