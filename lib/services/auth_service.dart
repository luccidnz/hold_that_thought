import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hold_that_thought/services/feature_flags.dart';

/// Service to manage user authentication
class AuthService {
  final SupabaseClient _supabaseClient;
  final FlutterSecureStorage _secureStorage;
  final FeatureFlags _featureFlags;
  
  static const String _sessionKey = 'auth.session';
  
  AuthService(this._supabaseClient, this._secureStorage, this._featureFlags);
  
  /// Get the current authenticated user
  User? get currentUser => _supabaseClient.auth.currentUser;
  
  /// Check if a user is signed in
  bool get isSignedIn => currentUser != null;
  
  /// Stream of auth state changes
  Stream<AuthState> get onAuthStateChange => _supabaseClient.auth.onAuthStateChange;
  
  /// Sign in with email magic link
  Future<void> signInWithMagicLink({required String email}) async {
    await _supabaseClient.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'holdthatthought://login-callback',
    );
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'holdthatthought://signup-callback',
    );
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    await _secureStorage.delete(key: _sessionKey);
  }
  
  /// Get device info for the current device
  Future<Map<String, dynamic>> getDeviceInfo() async {
    // This would typically use a package like device_info_plus
    // For simplicity, returning basic info:
    return {
      'id': 'current-device', // In a real app, generate a UUID and store it
      'name': 'Current Device',
      'lastActive': DateTime.now().toIso8601String(),
      'platform': 'Flutter',
    };
  }
  
  /// Delete all user data locally
  Future<void> deleteLocalUserData() async {
    // This would require coordination with other services
    // Here we'll just clear the auth session
    await signOut();
  }
  
  /// Persist the session securely
  Future<void> persistSession(Session session) async {
    await _secureStorage.write(
      key: _sessionKey,
      value: session.persistSessionString,
    );
  }
  
  /// Retrieve a persisted session
  Future<String?> getPersistedSession() async {
    return await _secureStorage.read(key: _sessionKey);
  }
  
  /// Check if auth is enabled via feature flag
  Future<bool> isAuthEnabled() async {
    return await _featureFlags.getAuthEnabled();
  }
  
  /// Migrate anonymous data to authenticated user
  /// Returns true if migration was successful
  Future<bool> migrateAnonymousToUser() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user to migrate to');
      }
      
      // Get a list of thoughts that need migration
      final thoughts = await _supabaseClient
          .from('thoughts_meta')
          .select()
          .filter('user_id', 'is', null);
      
      if (thoughts.isEmpty) {
        // No thoughts to migrate
        return true;
      }
      
      // For each thought, migrate its storage objects and update metadata
      for (final thought in thoughts) {
        final sha256 = thought['sha256'] as String;
        final isEncrypted = thought['e2ee'] as bool? ?? false;
        
        // Source and destination paths for audio file
        final sourceAudioPath = 'thoughts/${sha256}.${isEncrypted ? 'm4a.enc' : 'm4a'}';
        final destAudioPath = 'thoughts/$userId/${sha256}.${isEncrypted ? 'm4a.enc' : 'm4a'}';
        
        try {
          // Copy audio file to new location
          await _supabaseClient
              .storage
              .from('thoughts')
              .copy(sourceAudioPath, destAudioPath);
              
          // Update metadata record with userId
          await _supabaseClient
              .from('thoughts_meta')
              .update({'user_id': userId})
              .eq('id', thought['id']);
          
          // Delete old audio file
          await _supabaseClient
              .storage
              .from('thoughts')
              .remove([sourceAudioPath]);
        } catch (e) {
          // Log error but continue with next thought
          print('Error migrating thought ${thought['id']}: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Migration failed: $e');
      return false;
    }
  }
}

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final featureFlags = ref.watch(featureFlagsProvider);
  
  // Get Supabase client
  final client = Supabase.instance.client;
  
  return AuthService(
    client, 
    const FlutterSecureStorage(),
    featureFlags,
  );
});
