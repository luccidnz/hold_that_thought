import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/services/rag_service.dart';
import 'package:hold_that_thought/state/providers.dart';
import 'package:hold_that_thought/state/repository_providers.dart';

/// A widget that displays thoughts related to the current thought.
/// This is part of the RAG (Retrieval Augmented Generation) feature in Phase 10.
class RelatedPanel extends ConsumerWidget {
  final Thought currentThought;
  final int maxRelated;
  final VoidCallback? onRefresh;

  const RelatedPanel({
    Key? key,
    required this.currentThought,
    this.maxRelated = 3,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureFlagsAsync = ref.watch(ragEnabledProvider);
    
    // Don't show the panel if RAG is not enabled or still loading
    return featureFlagsAsync.when(
      data: (ragEnabled) {
        if (!ragEnabled) {
          return const SizedBox.shrink();
        }
        
        final relatedThoughts = ref.watch(relatedThoughtsProvider(currentThought.id));
        
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: relatedThoughts.when(
            data: (thoughts) {
              if (thoughts.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return _buildRelatedPanel(context, thoughts, ref);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Optional: show a message when no related thoughts are found
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Related Thoughts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No related thoughts found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (onRefresh != null)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  onPressed: onRefresh,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedPanel(BuildContext context, List<Thought> thoughts, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Related Thoughts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh related thoughts',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...thoughts.take(maxRelated).map((thought) => _buildRelatedItem(context, thought, ref)),
            if (thoughts.length > maxRelated)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to a view showing all related thoughts
                    // This could be implemented separately
                  },
                  child: Text('See ${thoughts.length - maxRelated} more'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedItem(BuildContext context, Thought thought, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        // Set this thought as selected - this should be used by the app to show its details
        ref.read(selectedThoughtIdProvider.notifier).state = thought.id;
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thought.title ?? 'Untitled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thought.transcript ?? 'No transcript',
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider that fetches related thoughts for a given thought ID
final relatedThoughtsProvider = FutureProvider.family<List<Thought>, String>((ref, thoughtId) async {
  // Check if RAG is enabled
  final ragEnabled = await ref.read(ragEnabledProvider.future);
  if (!ragEnabled) {
    return [];
  }

  final ragService = ref.read(ragServiceProvider);
  final repository = ref.read(thoughtRepositoryProvider);
  
  // Get the current thought
  final thought = await repository.getThought(thoughtId);
  if (thought == null) {
    return [];
  }
  
  // Get related thoughts using the RAG service
  return await ragService.suggestRelated(thoughtId);
});
