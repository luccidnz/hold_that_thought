import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/services/api_service.dart';
import 'package:hold_that_thought/services/auth_service.dart';
import 'package:hold_that_thought/services/crypto_service.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/services/rag_service.dart';
import 'package:hold_that_thought/services/sync/sync_provider.dart';
import 'package:hold_that_thought/services/sync/supabase/supabase_sync_provider.dart';
import 'package:hold_that_thought/services/vector_index.dart';
import 'package:hold_that_thought/state/auth_state.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides access to Hive boxes used throughout the app
class HiveBoxes {
  final Box? vectorIndexCacheBox;
  final Box? thoughtSummariesBox;
  final Box? dailyDigestsBox;
  
  HiveBoxes({
    this.vectorIndexCacheBox,
    this.thoughtSummariesBox,
    this.dailyDigestsBox,
  });
}

/// ServiceLocator provides a centralized way to access services via Riverpod providers.
/// This makes it easy to inject dependencies and mock services for testing.
class ServiceLocator {
  /// Private constructor to prevent instantiation
  ServiceLocator._();

  /// Initialize services that need to be set up before the app starts
  static Future<void> initialize() async {
    // Initialize any services that need setup before app starts
    // Like Supabase, Hive boxes, etc.
  }
}

/// Provider for secure storage, used by multiple services
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for FeatureFlags service
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return FeatureFlags(secureStorage);
});

/// Provider for Hive boxes
final hiveBoxesProvider = Provider<HiveBoxes>((ref) {
  // Try to get boxes if they're open, otherwise return null
  Box? vectorIndexCacheBox;
  Box? thoughtSummariesBox;
  Box? dailyDigestsBox;
  
  try {
    if (Hive.isBoxOpen('vector_index_cache')) {
      vectorIndexCacheBox = Hive.box('vector_index_cache');
    }
    if (Hive.isBoxOpen('thought_summaries')) {
      thoughtSummariesBox = Hive.box('thought_summaries');
    }
    if (Hive.isBoxOpen('daily_digests')) {
      dailyDigestsBox = Hive.box('daily_digests');
    }
  } catch (e) {
    print('Error accessing Hive boxes: $e');
  }
  
  return HiveBoxes(
    vectorIndexCacheBox: vectorIndexCacheBox,
    thoughtSummariesBox: thoughtSummariesBox,
    dailyDigestsBox: dailyDigestsBox,
  );
});

/// Feature flag providers that can be consumed across the app
final authEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getAuthEnabled();
});

final ragEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getRagEnabled();
});

final e2eeEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getE2eeEnabled();
});

final telemetryEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getTelemetryEnabled();
});

/// Provider for Supabase client
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (e) {
    // Supabase not initialized yet
    return null;
  }
});

/// Provider for AuthService
final authServiceProvider = Provider<AuthService?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  if (supabase == null) {
    return null;
  }
  
  final secureStorage = ref.watch(secureStorageProvider);
  final featureFlags = ref.watch(featureFlagsProvider);
  return AuthService(supabase, secureStorage, featureFlags);
});

/// Provider for CryptoService
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final featureFlags = ref.watch(featureFlagsProvider);
  return CryptoService(secureStorage, featureFlags);
});

/// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiService(secureStorage);
});

/// Provider for VectorIndex
final vectorIndexProvider = Provider<VectorIndex>((ref) {
  final hiveBoxes = ref.watch(hiveBoxesProvider);
  return VectorIndex(_cacheBox: hiveBoxes.vectorIndexCacheBox);
});

/// Provider for RAGService
final ragServiceProvider = Provider<RagService>((ref) {
  final vectorIndex = ref.watch(vectorIndexProvider);
  final featureFlags = ref.watch(featureFlagsProvider);
  final apiService = ref.watch(apiServiceProvider);
  final hiveBoxes = ref.watch(hiveBoxesProvider);
  
  return RagService(
    vectorIndex, 
    featureFlags, 
    ref,
    apiService,
    hiveBoxes.thoughtSummariesBox,
    hiveBoxes.dailyDigestsBox,
  );
});

/// Provider for SyncProvider
final syncProviderProvider = Provider<SyncProvider>((ref) {
  // We need to update the SupabaseSyncProvider constructor to accept these new parameters
  // For now we'll just create a basic instance
  return SupabaseSyncProvider();
});
