import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/services/rag_service.dart';
import 'package:hold_that_thought/state/providers.dart';
import 'package:hold_that_thought/services/open_file_helper.dart';
import 'package:hold_that_thought/widgets/related_panel.dart';

/// A bottom sheet that displays the detailed view of a thought.
class ThoughtDetailBottomSheet extends ConsumerWidget {
  final Thought thought;

  const ThoughtDetailBottomSheet({
    Key? key,
    required this.thought,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Handle bar at the top
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              
              // Title and actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thought.title ?? 'Untitled Thought',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(thought.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      tooltip: 'Play recording',
                      onPressed: () => _playRecording(context),
                    ),
                  ],
                ),
              ),
              
              // Divider
              const Divider(),
              
              // Transcript
              if (thought.transcript != null && thought.transcript!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transcript',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        thought.transcript!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              
              // Summary section (if RAG is enabled)
              _buildSummarySection(context, ref),
              
              // Related thoughts section
              RelatedPanel(
                currentThought: thought,
                onRefresh: () {
                  // Force refresh related thoughts
                  ref.invalidate(relatedThoughtsProvider(thought.id));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(thoughtSummaryProvider(thought.id));
    
    return summaryAsync.when(
      data: (summary) {
        if (summary == null) {
          return _buildGenerateSummaryButton(context, ref);
        }
        
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () {
                        // Regenerate summary
                        ref.invalidate(thoughtSummaryProvider(thought.id));
                      },
                      tooltip: 'Regenerate summary',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                // Key points
                if (summary.keyPoints != null && summary.keyPoints!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Key Points',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...summary.keyPoints!.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(point)),
                      ],
                    ),
                  )),
                ],
                
                // Action items
                if (summary.actionItems != null && summary.actionItems!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...summary.actionItems!.map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('◯ ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(action)),
                      ],
                    ),
                  )),
                ],
                
                // Tags
                if (summary.suggestedTags != null && summary.suggestedTags!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Suggested Tags',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: summary.suggestedTags!.map((tag) => Chip(
                      label: Text(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => _buildGenerateSummaryButton(context, ref),
    );
  }
  
  Widget _buildGenerateSummaryButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.summarize),
          label: const Text('Generate Summary'),
          onPressed: () async {
            // Check if RAG is enabled
            final ragEnabled = await ref.read(ragEnabledProvider.future);
            if (!ragEnabled) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Smart features are disabled. Enable them in settings.')),
              );
              return;
            }
            
            // Force refresh to generate summary
            ref.invalidate(thoughtSummaryProvider(thought.id));
          },
        ),
      ),
    );
  }
  
  void _playRecording(BuildContext context) async {
    try {
      // Since we can't get the WidgetRef here, just pass null
      // The openWithSystemPlayer will still work but won't be able to handle encrypted files
      await openWithSystemPlayer(thought.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play recording: $e')),
      );
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(date.weekday)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
  
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}

/// Provider for thought summaries
final thoughtSummaryProvider = FutureProvider.family<ThoughtSummary?, String>((ref, thoughtId) async {
  // Check if RAG is enabled
  final ragEnabled = await ref.read(ragEnabledProvider.future);
  if (!ragEnabled) {
    return null;
  }

  final ragService = ref.read(ragServiceProvider);
  return await ragService.summarizeThought(thoughtId);
});
