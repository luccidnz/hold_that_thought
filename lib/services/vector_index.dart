import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/service_locator.dart';

/// Represents a vector search result with ID and similarity score
class VectorSearchResult {
  final String id;
  final double similarity;

  VectorSearchResult({required this.id, required this.similarity});
}

/// A class for efficient vector similarity calculations and searches
class VectorIndex {
  // Map of document ID to embedding vector
  final Map<String, Float32List> _vectors = {};

  // Cache for similarity calculations to avoid redundant computation
  final Map<String, Map<String, double>> _similarityCache = {};

  // Counter for tracking upserts since last cache update
  int _upsertsSinceLastCache = 0;

  // Threshold for automatic caching
  static const int _cachingThreshold = 50;

  // Hive box for persisting the index
  final Box? _cacheBox;

  VectorIndex({this._cacheBox});

  /// Initialize the vector index from thoughts
  Future<void> initialize(List<Thought> thoughts) async {
    // Clear existing data
    _vectors.clear();
    _similarityCache.clear();

    // Load embeddings from thoughts
    for (final thought in thoughts) {
      if (thought.embedding != null && thought.embedding!.isNotEmpty) {
        final float32Embedding = _doubleListToFloat32List(thought.embedding!);
        _vectors[thought.id] = float32Embedding;
      }
    }

    // Load any cached similarities from persistent storage if not using Hive box
    if (_cacheBox == null) {
      await _loadSimilarityCache();
    } else {
      await initFromCache();
    }

    print('Vector index initialized with ${_vectors.length} embeddings');
  }

  /// Initialize the vector index from cache if available
  Future<void> initFromCache() async {
    if (_cacheBox == null) return;

    try {
      final cachedVectors = _cacheBox!.get('vectors');
      if (cachedVectors != null) {
        final List<dynamic> vectorsList = cachedVectors;
        for (final entry in vectorsList) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(entry);
          final id = map['id'] as String;
          final embedding = Float32List.fromList((map['embedding'] as List).cast<double>());
          _vectors[id] = embedding;
        }
      }
      print('Loaded ${_vectors.length} vectors from cache');
    } catch (e) {
      print('Error loading vector index from cache: $e');
    }
  }

  /// Get the number of vectors in the index
  int get size => _vectors.length;

  /// Add or update an embedding in the index (alias for backward compatibility)
  void addOrUpdateEmbedding(String thoughtId, List<double> embedding) {
    final float32Embedding = _doubleListToFloat32List(embedding);
    upsert(thoughtId, float32Embedding);
  }

  /// Insert or update a vector in the index
  void upsert(String id, Float32List embedding) {
    _vectors[id] = embedding;

    // Clear any cached similarities for this document
    _similarityCache.remove(id);
    _similarityCache.forEach((docId, cache) => cache.remove(id));

    _upsertsSinceLastCache++;

    // Automatically cache if threshold is reached
    if (_upsertsSinceLastCache >= _cachingThreshold) {
      if (_cacheBox != null) {
        _updateCache();
      } else {
        _scheduleSave();
      }
    }
  }

  /// Remove a vector from the index (alias for backward compatibility)
  void removeEmbedding(String thoughtId) {
    remove(thoughtId);
  }

  /// Remove a vector from the index
  void remove(String id) {
    _vectors.remove(id);

    // Clear any cached similarities for this document
    _similarityCache.remove(id);
    _similarityCache.forEach((docId, cache) => cache.remove(id));

    if (_cacheBox != null) {
      _updateCache();
    } else {
      _scheduleSave();
    }
  }

  /// Get the embedding for a specific ID
  Float32List? getEmbedding(String id) {
    return _vectors[id];
  }

  /// Find similar thoughts to a given thought ID (alias for backward compatibility)
  List<String> findSimilar(String thoughtId, {int limit = 5}) {
    if (!_vectors.containsKey(thoughtId)) {
      return [];
    }

    final results = topK(_vectors[thoughtId]!, limit, excludeIds: {thoughtId});
    return results.map((result) => result.id).toList();
  }

  /// Find the top k most similar vectors to the query vector
  List<VectorSearchResult> topK(Float32List queryEmbedding, int k, {Set<String>? excludeIds}) {
    final results = <VectorSearchResult>[];

    for (final entry in _vectors.entries) {
      // Skip if ID is in the exclude set
      if (excludeIds != null && excludeIds.contains(entry.key)) {
        continue;
      }

      // Calculate cosine similarity
      final similarity = _cosineSimilarity(queryEmbedding, entry.value);

      results.add(VectorSearchResult(id: entry.key, similarity: similarity));
    }

    // Sort by similarity (highest first)
    results.sort((a, b) => b.similarity.compareTo(a.similarity));

    // Return top k results
    return results.take(k).toList();
  }

  /// Find thoughts similar to a query embedding (alias for backward compatibility)
  List<String> queryByEmbedding(List<double> queryEmbedding, {int limit = 5}) {
    final float32Embedding = _doubleListToFloat32List(queryEmbedding);
    final results = topK(float32Embedding, limit);
    return results.map((result) => result.id).toList();
  }

  /// Calculate cosine similarity between two embeddings
  double _cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) {
      throw ArgumentError('Embeddings must have the same dimension');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    // Avoid division by zero
    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Convert a List<double> to Float32List
  Float32List _doubleListToFloat32List(List<double> list) {
    final float32List = Float32List(list.length);
    for (int i = 0; i < list.length; i++) {
      float32List[i] = list[i].toDouble();
    }
    return float32List;
  }

  /// Persist the vector index to cache
  Future<void> _updateCache() async {
    if (_cacheBox == null) return;

    try {
      final List<Map<String, dynamic>> vectorsList = [];

      for (final entry in _vectors.entries) {
        vectorsList.add({
          'id': entry.key,
          'embedding': entry.value.toList(),
        });
      }

      await _cacheBox.put('vectors', vectorsList);
      _upsertsSinceLastCache = 0;
    } catch (e) {
      print('Error caching vector index: $e');
    }
  }

  // Legacy code for similarity cache storage (for backward compatibility)
  // Box name for persisting the index
  static const String _boxName = 'vector_index_cache';

  /// Load similarity cache from persistent storage
  Future<void> _loadSimilarityCache() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final data = box.get('similarity_cache');

      if (data != null) {
        // Convert from dynamic to typed Map
        for (final entry in data.entries) {
          final thoughtId = entry.key as String;
          _similarityCache[thoughtId] = {};

          for (final innerEntry in (entry.value as Map).entries) {
            _similarityCache[thoughtId]![innerEntry.key as String] =
                (innerEntry.value as num).toDouble();
          }
        }
      }
    } catch (e) {
      print('Failed to load vector index cache: $e');
      // Continue with empty cache
    }
  }

  /// Save similarity cache to persistent storage
  Future<void> _saveSimilarityCache() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.put('similarity_cache', _similarityCache);
    } catch (e) {
      print('Failed to save vector index cache: $e');
    }
  }

  // Debounce save operations
  bool _saveScheduled = false;
  void _scheduleSave() {
    if (_saveScheduled) return;

    _saveScheduled = true;
    Future.delayed(const Duration(seconds: 5), () {
      _saveSimilarityCache();
      _saveScheduled = false;
    });
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    int vectorCount = _vectors.length;
    int cacheEntryCount = 0;

    for (final cache in _similarityCache.values) {
      cacheEntryCount += cache.length;
    }

    // Rough estimate of memory usage
    int vectorBytes = 0;
    for (final embedding in _vectors.values) {
      vectorBytes += embedding.length * 4; // 4 bytes per float32
    }

    return {
      'vectorCount': vectorCount,
      'cacheEntryCount': cacheEntryCount,
      'vectorMemoryBytes': vectorBytes,
      'approximateTotalMemoryKB': (vectorBytes + cacheEntryCount * 16) ~/ 1024,
    };
  }

  /// Force cache update (e.g., when app is going to background)
  Future<void> persistToCache() async {
    if (_cacheBox != null) {
      await _updateCache();
    } else {
      await _saveSimilarityCache();
    }
  }

  /// Clear the vector index
  void clear() {
    _vectors.clear();
    _similarityCache.clear();
    if (_cacheBox != null) {
      _updateCache();
    } else {
      _saveSimilarityCache();
    }
  }
}

/// Provider for the VectorIndex
final vectorIndexProvider = Provider<VectorIndex>((ref) {
  final hiveBoxes = ref.watch(hiveBoxesProvider);
  final vectorIndexBox = hiveBoxes.vectorIndexCacheBox;

  final vectorIndex = VectorIndex(_cacheBox: vectorIndexBox);
  return vectorIndex;
});
