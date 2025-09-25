import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/thought.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import '../services/feature_flags.dart';
import '../services/rag_service.dart';
import '../services/vector_index.dart';
import 'auth_state.dart' as app_auth;

final thoughtsBoxProvider = Provider<Box<Thought>>((_) => throw UnimplementedError('Hive not ready'));

final searchQueryProvider = StateProvider<String>((_) => '');
final tagFilterProvider   = StateProvider<List<String>>((_) => <String>[]);

enum SortMode { newest, oldest, longest, bestMatch }
final sortModeProvider    = StateProvider<SortMode>((_) => SortMode.newest);

enum SearchMode { keyword, semantic }
final searchModeProvider = StateProvider<SearchMode>((_) => SearchMode.keyword);

final transcriptionKeyOverrideProvider = StateProvider<String?>((_) => null);
final embeddingKeyOverrideProvider     = StateProvider<String?>((_) => null);

// Phase 10: Selected thought for detail view
final selectedThoughtIdProvider = StateProvider<String?>((ref) => null);

// Phase 10: Feature Flags provider is directly from the service file now
// Using the one defined in the FeatureFlags class

// Phase 10: Auth Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final supabaseClient = Supabase.instance.client;
  final featureFlags = ref.watch(featureFlagsProvider);
  return AuthService(
    supabaseClient, 
    const FlutterSecureStorage(),
    featureFlags,
  );
});

// Phase 10: Auth State provider
final authStateProvider = StateNotifierProvider<app_auth.AuthStateNotifier, app_auth.AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final featureFlags = ref.watch(featureFlagsProvider);
  return app_auth.AuthStateNotifier(
    authService: authService, 
    featureFlags: featureFlags,
  );
});

// Phase 10: Crypto Service provider
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  final featureFlags = ref.watch(featureFlagsProvider);
  return CryptoService(const FlutterSecureStorage(), featureFlags);
});

// Phase 10: RAG Service provider
final ragServiceProvider = Provider<RagService>((ref) {
  final vectorIndex = VectorIndex();
  final featureFlags = ref.watch(featureFlagsProvider);
  final apiService = ApiService(const FlutterSecureStorage());
  // Using null for Hive boxes initially - they'd be properly initialized elsewhere
  final Box? summariesBox = null;
  final Box? digestsBox = null;
  
  return RagService(
    vectorIndex,
    featureFlags,
    ref,
    apiService,
    summariesBox,
    digestsBox,
  );
});

// Phase 10: Daily Digest provider
final dailyDigestProvider = FutureProvider<String?>((ref) async {
  final featureFlags = ref.read(featureFlagsProvider);
  final isRagEnabled = await featureFlags.getRagEnabled();
  if (!isRagEnabled) {
    return null;
  }
  
  final ragService = ref.read(ragServiceProvider);
  final digest = await ragService.generateDailyDigest(DateTime.now());
  return digest.summary;
});
