import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transcription_service.dart';
import '../services/embedding_service.dart';
import '../state/providers.dart';
import '../models/thought.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _status = '';
  bool _busy = false;

  Future<void> _ping() async {
    setState(() { _busy = true; _status = 'Pinging…'; });
    final svc = TranscriptionService();
    try {
      final ok = await svc.ping();
      setState(() { _status = 'Ping: $ok'; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ping OK')));
    } catch (e) {
      setState(() { _status = 'Ping failed: $e'; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ping failed: $e')));
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  Future<void> _retranscribe() async {
    final box = ref.read(thoughtsBoxProvider);
    final svc = TranscriptionService();
    setState(() { _busy = true; _status = 'Re-transcribing…'; });
    int ok = 0, fail = 0;
    for (final t in box.values.toList()) {
      final current = (t.transcript ?? '');
      final needs = current.isEmpty || current == '(transcription failed)' || current.startsWith('Transcript of ');
      if (!needs) continue;
      try {
        final text = await svc.transcribeFile(t.path);
        final updated = Thought(id: t.id, path: t.path, createdAt: t.createdAt, durationMs: t.durationMs, transcript: text);
        await box.put(t.id, updated);
        ok++;
      } catch (_) { fail++; }
    }
    setState(() { _status = 'Done: $ok updated, $fail failed'; _busy = false; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-transcribe done: $ok/$fail')));
  }

  Future<void> _backfillEmbeddings() async {
    final box = ref.read(thoughtsBoxProvider);
    final emb = EmbeddingService();
    setState(() { _busy = true; _status = 'Backfilling embeddings…'; });
    int ok = 0, fail = 0;
    for (final t in box.values.toList()) {
      final needs = t.embedding == null && (t.transcript ?? '').isNotEmpty;
      if (!needs) continue;
      try {
        final e = await emb.embed(t.transcript!);
        final updated = t.copyWith(embedding: e);
        await box.put(t.id, updated);
        ok++;
      } catch (e) { fail++; }
    }
    setState(() { _busy = false; _status = 'Embedding backfill done: $ok / $fail failed'; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Embedding backfill: $ok updated; $fail failed')));
  }

  @override
  Widget build(BuildContext context) {
    final raw = Platform.environment['OPENAI_API_KEY'] ?? '';
    final hasKey = raw.isNotEmpty;
    String masked;
    if (raw.isEmpty) { masked = '(missing)'; }
    else if (raw.length <= 9) { masked = '${raw.substring(0, 3)}…'; }
    else { masked = '${raw.substring(0, 3)}…${raw.substring(raw.length - 4)}'; }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Diagnostics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('API key detected: ${hasKey ? "yes" : "no"}'),
          const SizedBox(height: 8),
          Text('OPENAI_API_KEY: $masked'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ElevatedButton(onPressed: _busy ? null : _ping, child: const Text('Ping OpenAI')),
            ElevatedButton(onPressed: _busy ? null : _retranscribe, child: const Text('Re-transcribe all')),
            ElevatedButton(onPressed: _busy ? null : _backfillEmbeddings, child: const Text('Backfill embeddings')),
          ]),
          const SizedBox(height: 12),
          Text(_status),
        ]),
      ),
    );
  }
}
