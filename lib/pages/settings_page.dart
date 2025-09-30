import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:hold_that_thought/state/sync_providers.dart';
import 'package:hold_that_thought/utils/keys.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _status = '';
  bool _busy = false;
  late TextEditingController _urlController;
  late TextEditingController _anonKeyController;
  late TextEditingController _openaiKeyController;
  User? _user;
  bool _hasOpenaiKey = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ref.read(supabaseUrlProvider));
    _anonKeyController = TextEditingController(text: ref.read(supabaseAnonKeyProvider));
    _openaiKeyController = TextEditingController();
    
    // Initialize auth state tracking
    try {
      final client = Supabase.instance.client;
      _user = client.auth.currentUser;
      client.auth.onAuthStateChange.listen((event) {
        if (mounted) {
          setState(() {
            _user = event.session?.user;
          });
        }
      });
    } catch (e) {
      debugPrint('[SETTINGS] Supabase not initialized: $e');
    }
    
    // Check for existing OpenAI API key
    _checkOpenaiKey();
  }
  
  Future<void> _checkOpenaiKey() async {
    final hasKey = await Keys.hasOpenaiApiKey;
    if (mounted) {
      setState(() {
        _hasOpenaiKey = hasKey;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    _openaiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveOpenaiKey() async {
    final key = _openaiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key'))
      );
      return;
    }
    
    try {
      await Keys.saveOpenaiApiKey(key);
      _openaiKeyController.clear();
      await _checkOpenaiKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OpenAI API key saved securely'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save key: $e'))
        );
      }
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final res = await Supabase.instance.client.auth.signInAnonymously();
      debugPrint("[AUTH] anon tap -> ${res.user?.id}");
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in: ${res.user?.id ?? 'NULL'}'))
        );
      }
    } catch (e) {
      debugPrint("[AUTH] anon sign-in error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e'))
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out'))
        );
      }
    } catch (e) {
      debugPrint("[AUTH] sign-out error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-out failed: $e'))
        );
      }
    }
  }

  Future<void> _testDatabaseConnection() async {
    try {
      final client = Supabase.instance.client;
      var user = client.auth.currentUser;
      
      // Ensure user is signed in
      if (user == null) {
        final res = await client.auth.signInAnonymously();
        user = res.user;
      }
      
      if (user == null) {
        throw Exception('Could not sign in');
      }
      
      // Insert a test record
      await client.from('thoughts').insert({
        'user_id': user.id,
        'text': 'doctor smoke test',
        'source': 'android',
      });
      
      // Count records for this user
      final data = await client.from('thoughts')
          .select('id')
          .eq('user_id', user.id);
      final count = (data as List).length;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DB OK (user ${user.id.substring(0,8)}) • count=$count'))
        );
      }
    } catch (e) {
      debugPrint("[DB_TEST] error: $e");
      String message = 'Database test failed';
      if (e is PostgrestException) {
        message = 'DB Error: ${e.message}';
      } else {
        message = 'DB Error: $e';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message))
        );
      }
    }
  }

  Future<void> _ping() async {
    // ... (existing implementation)
  }

  Future<void> _retranscribe() async {
    // ... (existing implementation)
  }

  Future<void> _backfillEmbeddings() async {
    // ... (existing implementation)
  }

  Widget _buildCloudSyncSection() {
    final syncEnabled = ref.watch(syncEnabledProvider);
    final syncStats = ref.watch(syncStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text('Cloud Sync (Supabase)', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(
          title: const Text('Enable Cloud Sync'),
          value: syncEnabled,
          onChanged: (value) {
            ref.read(syncEnabledProvider.notifier).state = value;
          },
        ),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(labelText: 'Supabase URL'),
          onChanged: (value) => ref.read(supabaseUrlProvider.notifier).state = value,
        ),
        TextField(
          controller: _anonKeyController,
          decoration: const InputDecoration(labelText: 'Supabase Anon Key'),
          onChanged: (value) => ref.read(supabaseAnonKeyProvider.notifier).state = value,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: _user == null
                  ? _signInAnonymously
                  : null,
              child: const Text('Sign In Anonymously'),
            ),
            ElevatedButton(
              onPressed: _user != null
                  ? _signOut
                  : null,
              child: const Text('Sign Out'),
            ),
            ElevatedButton(
              onPressed: _testDatabaseConnection,
              child: const Text('Test Database Connection'),
            ),
            ElevatedButton(
              onPressed: () => ref.read(syncServiceProvider).processQueue(),
              child: const Text('Backup Now'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('User ID: ${_user?.id ?? 'Not signed in'}'),
            ),
            if (_user != null)
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy User ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _user!.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User ID copied to clipboard'))
                  );
                },
              ),
          ],
        ),
        syncStats.when(
          data: (stats) => Text('Sync Queue: ${stats.pending} / ${stats.total}'),
          loading: () => const Text('Sync Queue: Loading...'),
          error: (e, s) => Text('Sync Queue: Error: $e'),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text('Data Management', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : _exportAll,
          child: const Text('Export All as ZIP'),
        ),
      ],
    );
  }

  Future<void> _exportAll() async {
    setState(() { _busy = true; _status = 'Exporting…'; });
    try {
      final repo = ref.read(thoughtRepositoryProvider);
      final thoughts = await repo.getAll();
      if (thoughts.isEmpty) {
        setState(() { _status = 'No thoughts to export.'; _busy = false; });
        return;
      }

      final archive = Archive();
      final manifest = [];

      for (final thought in thoughts) {
        final audioFile = File(thought.path);
        if (await audioFile.exists()) {
          final audioBytes = await audioFile.readAsBytes();
          final safeTitle = thought.title?.replaceAll(RegExp(r'[^\w\s-]'), '_') ?? thought.id;
          final dirName = '${thought.createdAt.toIso8601String().split('T').first}_$safeTitle';

          archive.addFile(ArchiveFile('$dirName/audio.m4a', audioBytes.length, audioBytes));

          if (thought.transcript != null) {
            final transcriptBytes = utf8.encode(thought.transcript!);
            archive.addFile(ArchiveFile('$dirName/transcript.txt', transcriptBytes.length, transcriptBytes));
          }

          manifest.add({
            'id': thought.id,
            'createdAt': thought.createdAt.toIso8601String(),
            'title': thought.title,
            'durationMs': thought.durationMs,
            'audioPath': '$dirName/audio.m4a',
            'transcriptPath': thought.transcript != null ? '$dirName/transcript.txt' : null,
          });
        }
      }

      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      await FileSaver.instance.saveFile(
        name: 'hold_that_thought_export_${DateTime.now().toIso8601String()}',
        bytes: Uint8List.fromList(zipData),
        mimeType: MimeType.zip,
      );

      setState(() { _status = 'Export complete!'; });
    } catch (e) {
      setState(() { _status = 'Export failed: $e'; });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Diagnostics')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOpenAiSection(),
              _buildCloudSyncSection(),
              _buildDataManagementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenAiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OpenAI Configuration', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text('API key detected: ${_hasOpenaiKey ? "yes" : "no"}'),
        const SizedBox(height: 12),
        TextField(
          controller: _openaiKeyController,
          decoration: const InputDecoration(
            labelText: 'OpenAI API Key',
            hintText: 'sk-...',
            helperText: 'Stored securely on device',
          ),
          obscureText: true,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _saveOpenaiKey,
          child: const Text('Save API Key'),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          ElevatedButton(onPressed: _busy ? null : _ping, child: const Text('Ping OpenAI')),
          ElevatedButton(
              onPressed: _busy ? null : _retranscribe, child: const Text('Re-transcribe all')),
          ElevatedButton(
              onPressed: _busy ? null : _backfillEmbeddings,
              child: const Text('Backfill embeddings')),
        ]),
        const SizedBox(height: 12),
        Text(_status),
      ],
    );
  }
}
