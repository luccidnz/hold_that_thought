import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'services/hive_boot.dart';
import 'state/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase before everything else
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    
    // Ensure anonymous sign-in
    final client = Supabase.instance.client;
    final sess = client.auth.currentSession;
    if (sess?.user == null) {
      try {
        await client.auth.signInAnonymously();
        debugPrint('[BOOT] supa init ok; user=${client.auth.currentUser?.id ?? "null"}');
      } catch (e) {
        debugPrint('[BOOT] anonymous sign-in failed: $e');
      }
    } else {
      debugPrint('[BOOT] supa init ok; user=${client.auth.currentUser?.id ?? "null"}');
    }
  } else {
    debugPrint('[BOOT] Supabase not configured - missing URL or key');
  }
  
  final box = await openThoughtsBoxRobust();
  runApp(
    ProviderScope(
      overrides: [ thoughtsBoxProvider.overrideWithValue(box) ],
      child: const HoldThatThoughtApp(),
    ),
  );
}