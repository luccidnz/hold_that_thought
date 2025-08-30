import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/thought.dart';
import '../services/transcription_service.dart';
import '../services/embedding_service.dart';
import '../state/providers.dart';

class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});
  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  final _rec = AudioRecorder();
  bool _isRecording = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    unawaited(_initAudio());
  }

  Future<void> _initAudio() async {
    try {
      final has = await _rec.hasPermission();
      debugPrint('mic permission: $has');
    } catch (e, st) {
      debugPrint('record init error: $e\n$st');
    }
  }

  Future<String> _transcribe(String path) async {
    final svc = TranscriptionService();
    try {
      final text = await svc.transcribeFile(path);
      return text;
    } catch (e) {
      // ignore: avoid_print
      print('Transcription failed: $e');
      return '(transcription failed)';
    }
  }

  Future<void> _toggle() async {
    if (_isRecording) {
      final stoppedPath = await _rec.stop();
      debugPrint('stopped → $stoppedPath');
      setState(() => _isRecording = false);

      if (stoppedPath != null) {
        final createdAt = _startedAt ?? DateTime.now();
        final durMs = DateTime.now().difference(createdAt).inMilliseconds;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transcribing…'), duration: Duration(seconds: 2)),
          );
        }

        final transcript = await _transcribe(stoppedPath);

  if (!mounted) return;
  final box = ref.read(thoughtsBoxProvider);
        final id = 't_${DateTime.now().millisecondsSinceEpoch}';
        final thought = Thought(
          id: id,
          path: stoppedPath,
          createdAt: createdAt,
          durationMs: durMs,
          transcript: transcript,
        );
        await box.put(id, thought);
        unawaited(() async {
          try {
            if (transcript.isNotEmpty && transcript != '(transcription failed)') {
              final embSvc = EmbeddingService();
              final emb = await embSvc.embed(transcript);
              final updated = thought.copyWith(embedding: emb);
              await box.put(id, updated);
            }
          } catch (e) {
            // ignore: avoid_print
            print('Embedding failed: $e');
          }
        }());

        if (!mounted) return;
        if (transcript == '(transcription failed)') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved thought (transcription failed)')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved thought with transcript')),
          );
        }
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/thought_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _startedAt = DateTime.now();
      await _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      debugPrint('recording → $path');
      setState(() => _isRecording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hold That Thought'),
        actions: [
          IconButton(
            tooltip: 'Thoughts List',
            onPressed: () => context.push('/list'),
            icon: const Icon(Icons.list),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: const Center(child: Text('Capture Page')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggle,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        label: Text(_isRecording ? 'Stop' : 'Record'),
      ),
    );
  }
}
