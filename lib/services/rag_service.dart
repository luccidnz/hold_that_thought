import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/api_service.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/services/vector_index.dart';
import 'package:hold_that_thought/state/auth_state.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model representing a summarization result
class ThoughtSummary {
  final String thoughtId;
  final String summary;
  final List<String>? keyPoints;
  final List<String>? actionItems;
  final List<String>? suggestedTags;
  final String? memoryHook;
  final DateTime createdAt;

  ThoughtSummary({
    required this.thoughtId,
    required this.summary,
    this.keyPoints,
    this.actionItems,
    this.suggestedTags,
    this.memoryHook,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'thoughtId': thoughtId,
      'summary': summary,
      'keyPoints': keyPoints,
      'actionItems': actionItems,
      'suggestedTags': suggestedTags,
      'memoryHook': memoryHook,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ThoughtSummary.fromJson(Map<String, dynamic> json) {
    return ThoughtSummary(
      thoughtId: json['thoughtId'],
      summary: json['summary'],
      keyPoints: (json['keyPoints'] as List?)?.cast<String>(),
      actionItems: (json['actionItems'] as List?)?.cast<String>(),
      suggestedTags: (json['suggestedTags'] as List?)?.cast<String>(),
      memoryHook: json['memoryHook'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Model representing a daily digest of thoughts
class DailyDigest {
  final DateTime date;
  final String summary;
  final List<String> thoughtIds;
  final List<String>? themes;
  final String? memoryHook;
  final DateTime createdAt;

  DailyDigest({
    required this.date,
    required this.summary,
    required this.thoughtIds,
    this.themes,
    this.memoryHook,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'summary': summary,
      'thoughtIds': thoughtIds,
      'themes': themes,
      'memoryHook': memoryHook,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyDigest.fromJson(Map<String, dynamic> json) {
    return DailyDigest(
      date: DateTime.parse(json['date']),
      summary: json['summary'],
      thoughtIds: (json['thoughtIds'] as List).cast<String>(),
      themes: (json['themes'] as List?)?.cast<String>(),
      memoryHook: json['memoryHook'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Service for RAG (Retrieval Augmented Generation) functionality
class RagService {
  final VectorIndex _vectorIndex;
  final FeatureFlags _featureFlags;
  final Ref _ref;
  final ApiService _apiService;
  final Box? _summariesBox;
  final Box? _digestsBox;

  static const String _summariesBoxName = 'thought_summaries';
  static const String _digestsBoxName = 'daily_digests';

  RagService(
    this._vectorIndex,
    this._featureFlags,
    this._ref,
    this._apiService,
    this._summariesBox,
    this._digestsBox,
  );

  /// Initialize the RAG service
  Future<void> initialize() async {
    // Initialize vector index with all thoughts
    final thoughtRepo = _ref.read(thoughtRepositoryProvider);
    final thoughts = await thoughtRepo.getAll();
    await _vectorIndex.initialize(thoughts);

    // Ensure Hive boxes are open if not provided
    if (_summariesBox == null) {
      await Hive.openBox(_summariesBoxName);
    }
    if (_digestsBox == null) {
      await Hive.openBox(_digestsBoxName);
    }
  }

  /// Suggest related thoughts for a given thought
  Future<List<Thought>> suggestRelated(String thoughtId, {int k = 5}) async {
    final isRagEnabled = await _featureFlags.getRagEnabled();
    if (!isRagEnabled) return [];

    final relatedIds = await _vectorIndex.findSimilar(thoughtId, limit: k);
    if (relatedIds.isEmpty) return [];

    // Get the actual thoughts
    final thoughtRepo = _ref.read(thoughtRepositoryProvider);
    final relatedThoughts = <Thought>[];

    for (final id in relatedIds) {
      final thought = await thoughtRepo.getThought(id);
      if (thought != null) {
        relatedThoughts.add(thought);
      }
    }

    return relatedThoughts;
  }

  /// Generate a daily digest for a specific date
  Future<DailyDigest> generateDailyDigest(DateTime date) async {
    // Check for cached digest first
    final cached = await getCachedDailyDigest(date);
    if (cached != null) {
      return cached;
    }

    // Get thoughts for the specified date
    final thoughtRepo = _ref.read(thoughtRepositoryProvider);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all thoughts and filter by date range
    final allThoughts = await thoughtRepo.getAll();
    final thoughts = allThoughts.where((thought) =>
      thought.createdAt.isAfter(startOfDay) &&
      thought.createdAt.isBefore(endOfDay)
    ).toList();

    if (thoughts.isEmpty) {
      return DailyDigest(
        date: date,
        summary: 'No thoughts recorded on this day.',
        thoughtIds: [],
      );
    }

    // Generate digest using LLM
    try {
      final digest = await _generateDailyDigest(date, thoughts);
      await cacheDailyDigest(digest);
      return digest;
    } catch (e) {
      print('Error generating daily digest: $e');

      // Return a basic digest on error
      return DailyDigest(
        date: date,
        summary: 'Failed to generate daily digest: ${e.toString()}',
        thoughtIds: thoughts.map((t) => t.id).toList(),
      );
    }
  }

  /// Get a cached summary for a thought
  Future<ThoughtSummary?> getCachedSummary(String thoughtId) async {
    final box = await Hive.openBox<Map>(_summariesBoxName);
    final data = box.get(thoughtId);
    if (data == null) return null;

    return ThoughtSummary.fromJson(Map<String, dynamic>.from(data));
  }

  /// Cache a summary
  Future<void> cacheSummary(ThoughtSummary summary) async {
    final box = await Hive.openBox<Map>(_summariesBoxName);
    await box.put(summary.thoughtId, summary.toJson());
  }

  /// Generate a daily digest using LLM
  Future<DailyDigest> _generateDailyDigest(DateTime date, List<Thought> thoughts) async {
    // Prepare the transcripts
    final transcripts = thoughts
        .where((t) => t.transcript != null && t.transcript!.isNotEmpty)
        .map((t) => t.transcript!)
        .join('\n\n---\n\n');

    if (transcripts.isEmpty) {
      return DailyDigest(
        date: date,
        summary: 'No transcript content available for this day.',
        thoughtIds: thoughts.map((t) => t.id).toList(),
      );
    }

    // Prepare the prompt for LLM
    final promptText = '''
You are an AI assistant helping to summarize a day's worth of thought recordings.
Create a cohesive summary that captures the main themes and highlights from these thoughts,
as if writing a journal entry for the day.

Here are transcripts from thought recordings on ${date.month}/${date.day}/${date.year}:

$transcripts

Please provide:
1. A daily summary (3-5 sentences)
2. Main themes or topics
3. A memorable "memory hook" for the day (one short sentence)
''';

    try {
      // Use the APIService to generate the digest
      final response = await _apiService.callLlm(promptText);

      // Parse the response
      final Map<String, dynamic> parsed = _parseResponse(response);

      // Create and return the digest
      return DailyDigest(
        date: date,
        summary: parsed['summary'] ?? 'Summary not available',
        thoughtIds: thoughts.map((t) => t.id).toList(),
        themes: parsed['themes']?.cast<String>() ?? [],
        memoryHook: parsed['memoryHook'] ?? '',
      );
    } catch (e) {
      print('Error in _generateDailyDigest: $e');
      return DailyDigest(
        date: date,
        summary: 'Failed to generate daily digest: ${e.toString()}',
        thoughtIds: thoughts.map((t) => t.id).toList(),
      );
    }
  }

  /// Get a cached daily digest
  Future<DailyDigest?> getCachedDailyDigest(DateTime date) async {
    final dateString = '${date.year}-${date.month}-${date.day}';
    final box = await Hive.openBox<Map>(_digestsBoxName);
    final data = box.get(dateString);
    if (data == null) return null;

    return DailyDigest.fromJson(Map<String, dynamic>.from(data));
  }

  /// Cache a daily digest
  Future<void> cacheDailyDigest(DailyDigest digest) async {
    final dateString = '${digest.date.year}-${digest.date.month}-${digest.date.day}';
    final box = await Hive.openBox<Map>(_digestsBoxName);
    await box.put(dateString, digest.toJson());
  }

  /// Summarize a single thought
  Future<ThoughtSummary> summarizeThought(String thoughtId) async {
    // Check for cached summary first
    final cached = await getCachedSummary(thoughtId);
    if (cached != null) {
      return cached;
    }

    // Fetch the thought
    final thoughtRepo = _ref.read(thoughtRepositoryProvider);
    final thought = await thoughtRepo.getThought(thoughtId);
    if (thought == null) {
      throw Exception('Thought not found: $thoughtId');
    }

    // If no transcript, return a basic summary
    if (thought.transcript == null || thought.transcript!.isEmpty) {
      final summary = ThoughtSummary(
        thoughtId: thoughtId,
        summary: 'No transcript available for summarization.',
      );
      await cacheSummary(summary);
      return summary;
    }

    // Try to generate a summary using LLM
    try {
      final summary = await _generateSummary(thought);
      await cacheSummary(summary);
      return summary;
    } catch (e) {
      print('Error generating summary: $e');

      // Return a basic summary on error
      final summary = ThoughtSummary(
        thoughtId: thoughtId,
        summary: 'Failed to generate summary: ${e.toString()}',
      );
      await cacheSummary(summary);
      return summary;
    }
  }

  /// Upload embeddings to Supabase if enabled
  Future<void> uploadEmbeddingToCloud(String thoughtId, List<double> embedding) async {
    final isRagEnabled = await _featureFlags.getRagEnabled();
    if (!isRagEnabled) return;

    final authState = _ref.read(authStateProvider);
    if (!authState.isSignedIn) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      // Get the remoteId for the thought
      final thoughtRepo = _ref.read(thoughtRepositoryProvider);
      final thought = await thoughtRepo.getThought(thoughtId);
      if (thought == null || thought.remoteId == null) return;

      // Update the thoughts_meta table with the embedding
      await client.from('thoughts_meta').update({
        'embedding': embedding,
      }).eq('id', thought.remoteId!).eq('user_id', userId);
    } catch (e) {
      print('Failed to upload embedding to cloud: $e');
    }
  }

  /// Helper method to parse LLM response into structured data
  Map<String, dynamic> _parseResponse(String response) {
    // This is a simplified parser - in production, a more robust one would be needed
    final result = <String, dynamic>{};

    // Try to extract summary
    final summaryMatch = RegExp(r'(?:summary|Summary)[:\s]+(.*?)(?:\n\n|\n\d\.|\$)', dotAll: true).firstMatch(response);
    if (summaryMatch != null) {
      result['summary'] = summaryMatch.group(1)?.trim();
    }

    // Try to extract key points
    final keyPointsMatches = RegExp(r'(?:key points|Key points|Key Points)[:\s]+(.*?)(?:\n\n|\n\d\.|\$)', dotAll: true).firstMatch(response);
    if (keyPointsMatches != null) {
      final pointsText = keyPointsMatches.group(1);
      final points = RegExp(r'[-•*]\s+(.*?)(?:\n|$)').allMatches(pointsText ?? '')
          .map((m) => m.group(1)?.trim())
          .where((p) => p != null && p.isNotEmpty)
          .map((p) => p!)
          .toList();
      result['keyPoints'] = points;
    }

    // Try to extract action items
    final actionItemsMatches = RegExp(r'(?:action items|Action items|Action Items)[:\s]+(.*?)(?:\n\n|\n\d\.|\$)', dotAll: true).firstMatch(response);
    if (actionItemsMatches != null) {
      final itemsText = actionItemsMatches.group(1);
      final items = RegExp(r'[-•*]\s+(.*?)(?:\n|$)').allMatches(itemsText ?? '')
          .map((m) => m.group(1)?.trim())
          .where((p) => p != null && p.isNotEmpty)
          .map((p) => p!)
          .toList();
      result['actionItems'] = items;
    }

    // Try to extract tags
    final tagsMatch = RegExp(r'(?:tags|Tags|suggested tags|Suggested tags|Suggested Tags)[:\s]+(.*?)(?:\n\n|\n\d\.|\$)', dotAll: true).firstMatch(response);
    if (tagsMatch != null) {
      final tagsText = tagsMatch.group(1)?.trim() ?? '';
      final tags = tagsText.split(RegExp(r'[,\s]+'))
          .where((t) => t.isNotEmpty)
          .toList();
      result['suggestedTags'] = tags;
    }

    // Try to extract themes
    final themesMatch = RegExp(r'(?:themes|Themes|main themes|Main themes|Main Themes)[:\s]+(.*?)(?:\n\n|\n\d\.|\$)', dotAll: true).firstMatch(response);
    if (themesMatch != null) {
      final themesText = themesMatch.group(1);
      final themes = RegExp(r'[-•*]\s+(.*?)(?:\n|$)').allMatches(themesText ?? '')
          .map((m) => m.group(1)?.trim())
          .where((t) => t != null && t.isNotEmpty)
          .map((t) => t!)
          .toList();

      // If no bullet points were found, try splitting by commas
      if (themes.isEmpty && themesText != null) {
        final commaThemes = themesText.trim().split(RegExp(r'[,\s]+'))
            .where((t) => t.isNotEmpty)
            .toList();
        result['themes'] = commaThemes;
      } else {
        result['themes'] = themes;
      }
    }

    // Try to extract memory hook
    final hookMatch = RegExp(r'(?:memory hook|Memory hook|Memory Hook)[:\s]+(.*?)(?:\n\n|\n\d\.|\$)', dotAll: true).firstMatch(response);
    if (hookMatch != null) {
      result['memoryHook'] = hookMatch.group(1)?.trim();
    }

    return result;
  }

  /// Generate a summary using LLM
  Future<ThoughtSummary> _generateSummary(Thought thought) async {
    // Prepare the prompt for LLM
    final promptText = '''
You are an AI assistant helping to analyze and summarize a thought recording.
Extract key information and provide a concise summary, key points,
any action items, suggested tags, and a memorable one-sentence "memory hook"
that captures the essence of the thought.

Here is the transcript of a thought recording:

"${thought.transcript}"

Please provide:
1. A concise summary (2-3 sentences)
2. Key points (bullet points)
3. Action items (if any)
4. Suggested tags (3-5 keywords)
5. A memorable "memory hook" (one short sentence)
''';

    try {
      // Use the APIService to generate the summary
      final response = await _apiService.callLlm(promptText);

      // Parse the response
      final Map<String, dynamic> parsed = _parseResponse(response);

      // Create and return the summary
      return ThoughtSummary(
        thoughtId: thought.id,
        summary: parsed['summary'] ?? 'Summary not available',
        keyPoints: parsed['keyPoints']?.cast<String>() ?? [],
        actionItems: parsed['actionItems']?.cast<String>() ?? [],
        suggestedTags: parsed['suggestedTags']?.cast<String>() ?? [],
        memoryHook: parsed['memoryHook'] ?? '',
      );
    } catch (e) {
      print('Error in _generateSummary: $e');
      return ThoughtSummary(
        thoughtId: thought.id,
        summary: 'Failed to generate summary: ${e.toString()}',
      );
    }
  }
}

// The provider for this service is in service_locator.dart
