import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/repository/thought_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hold_that_thought/services/sync/supabase/supabase_sync_provider.dart';
import 'package:hold_that_thought/services/sync/sync_provider.dart';
import 'package:hold_that_thought/services/sync_service.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:hold_that_thought/state/sync_events.dart';

final supabaseUrlProvider = StateProvider<String>((ref) {
  return dotenv.env['SUPABASE_URL'] ?? '';
});

final supabaseAnonKeyProvider = StateProvider<String>((ref) {
  return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
});

final syncEnabledProvider = StateProvider<bool>((ref) => false);

final syncProvider = Provider<SyncProvider>((ref) {
  final url = ref.watch(supabaseUrlProvider);
  final anonKey = ref.watch(supabaseAnonKeyProvider);

  final provider = SupabaseSyncProvider();
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    provider.configure(url, anonKey);
  }
  return provider;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final syncProvider = ref.watch(syncProvider);
  final thoughtRepository = ref.watch(thoughtRepositoryProvider);

  final service = SyncService(
    provider: syncProvider,
    repository: thoughtRepository,
    ref: ref,
  );

  final user = ref.watch(supabaseUserProvider);
  service.setUserId(user?.id);

  service.start();
  ref.onDispose(() => service.dispose());

  return service;
});

// Provider to get the current Supabase user
final supabaseUserProvider = StateProvider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (e, s) => null,
  );
});

// Provider to expose Supabase auth state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final syncProvider = ref.watch(syncProvider);
   if (syncProvider is SupabaseSyncProvider) {
    final client = syncProvider.client;
    if (client != null) {
      return client.auth.onAuthStateChange;
    }
  }
  return const Stream.empty();
});

// A simple Riverpod event channel
class SyncEventBus extends StateNotifier<SyncEvent?> {
  SyncEventBus() : super(null);
  void emit(SyncEvent e) => state = e;
}

final syncEventBusProvider = StateNotifierProvider<SyncEventBus, SyncEvent?>(
  (ref) => SyncEventBus(),
);
