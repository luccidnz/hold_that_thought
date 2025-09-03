import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hold_that_thought/services/auth_service.dart';
import 'package:hold_that_thought/services/feature_flags.dart';

/// Enum representing the authentication state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

/// Class representing the current authentication state
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Whether the user is signed in
  bool get isSignedIn => status == AuthStatus.authenticated && user != null;

  /// Whether authentication is currently in progress
  bool get isAuthenticating => status == AuthStatus.authenticating;

  /// Whether there was an authentication error
  bool get hasError => status == AuthStatus.error;
}

/// Notifier for the authentication state
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FeatureFlags _featureFlags;

  AuthStateNotifier({
    required AuthService authService,
    required FeatureFlags featureFlags,
  })  : _authService = authService,
        _featureFlags = featureFlags,
        super(AuthState()) {
    _initialize();
  }

  /// Initialize the auth state
  Future<void> _initialize() async {
    final isAuthEnabled = await _featureFlags.getAuthEnabled();
    if (!isAuthEnabled) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final user = _authService.currentUser;
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    // Listen for auth state changes
    _authService.onAuthStateChange.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: authState.session?.user,
        );
      } else if (authState.event == AuthChangeEvent.signedOut) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        );
      }
    });
  }

  /// Sign in with magic link
  Future<void> signInWithMagicLink(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating);
      await _authService.signInWithMagicLink(email: email);
      // Note: actual auth state change will be handled by the listener
      // For UX reasons, we keep the authenticating state here
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating);
      final response = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Authentication failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating);
      final response = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Check your email for confirmation',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clear any error state
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Delete user data from this device
  Future<void> deleteLocalUserData() async {
    try {
      await _authService.deleteLocalUserData();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Migrate anonymous data to authenticated user
  Future<bool> migrateAnonymousToUser() async {
    try {
      return await _authService.migrateAnonymousToUser();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

/// Provider for the auth state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final featureFlags = ref.watch(featureFlagsProvider);

  return AuthStateNotifier(
    authService: authService,
    featureFlags: featureFlags,
  );
});
