import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/services/rag_service.dart';
import 'package:hold_that_thought/state/providers.dart';
import 'package:intl/intl.dart';

/// A widget that displays a daily digest of thoughts.
class DailyDigestCard extends ConsumerWidget {
  final DateTime date;
  final VoidCallback? onRefresh;

  const DailyDigestCard({
    Key? key,
    required this.date,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureFlagsAsync = ref.watch(ragEnabledProvider);

    // Don't show the card if RAG is not enabled or still loading
    return featureFlagsAsync.when(
      data: (ragEnabled) {
        if (!ragEnabled) {
          return const SizedBox.shrink();
        }

        final digestAsync = ref.watch(dailyDigestProvider(date));

        return digestAsync.when(
          data: (digest) {
            if (digest == null) {
              return _buildEmptyState(context);
            }

            return _buildDigestCard(context, digest, ref);
          },
          loading: () => _buildLoadingState(context),
          error: (_, __) => _buildErrorState(context, ref),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(width: 16),
            Text(
              'Preparing your daily digest...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Digest',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No digest available for ${DateFormat('EEEE, MMMM d').format(date)}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRefresh != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Generate Digest'),
                  onPressed: onRefresh,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Digest',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to generate digest for ${DateFormat('EEEE, MMMM d').format(date)}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                onPressed: onRefresh,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigestCard(BuildContext context, DailyDigest digest, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Digest',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              digest.summary,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            if (digest.themes != null && digest.themes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Themes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: digest.themes!.map((theme) => Chip(
                  label: Text(theme),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to full daily digest view
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Full digest view coming soon')),
                  );
                },
                child: const Text('View Full Digest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider for daily digest
final dailyDigestProvider = FutureProvider.family<DailyDigest?, DateTime>((ref, date) async {
  // Check if RAG is enabled
  final ragEnabled = await ref.read(ragEnabledProvider.future);
  if (!ragEnabled) {
    return null;
  }

  final ragService = ref.read(ragServiceProvider);
  return await ragService.generateDailyDigest(date);
});
