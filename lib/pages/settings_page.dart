import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:hold_that_thought/state/sync_providers.dart';

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

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ref.read(supabaseUrlProvider));
    _anonKeyController = TextEditingController(text: ref.read(supabaseAnonKeyProvider));
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
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
    final user = ref.watch(supabaseUserProvider);
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
              onPressed: user == null
                  ? () => ref.read(syncProvider).ensureSignedIn()
                  : null,
              child: const Text('Sign In Anonymously'),
            ),
            ElevatedButton(
              onPressed: user != null
                  ? () => ref.read(syncProvider).signOut()
                  : null,
              child: const Text('Sign Out'),
            ),
            ElevatedButton(
              onPressed: () => ref.read(syncServiceProvider).processQueue(),
              child: const Text('Backup Now'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('User ID: ${user?.id ?? 'Not signed in'}'),
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
    final raw = Platform.environment['OPENAI_API_KEY'] ?? '';
    final hasKey = raw.isNotEmpty;
    String masked;
    if (raw.isEmpty) {
      masked = '(missing)';
    } else if (raw.length <= 9) {
      masked = '${raw.substring(0, 3)}…';
    } else {
      masked = '${raw.substring(0, 3)}…${raw.substring(raw.length - 4)}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Diagnostics')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('API key detected: ${hasKey ? "yes" : "no"}'),
              const SizedBox(height: 8),
              Text('OPENAI_API_KEY: $masked'),
              const SizedBox(height: 8),
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
              _buildCloudSyncSection(),
              _buildDataManagementSection(),
            ],
          ),
        ),
      ),
    );
  }
}
