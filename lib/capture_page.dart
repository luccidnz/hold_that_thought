import 'package:flutter/material.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
// removed unused import

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});
  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final _rec = AudioRecorder(); // record v6 API
  bool _isRecording = false;

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

  Future<void> _toggle() async {
    if (_isRecording) {
      final path = await _rec.stop();
      debugPrint('stopped → $path');
      setState(() => _isRecording = false);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/thought_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
      appBar: AppBar(title: const Text('Hold That Thought')),
      body: const Center(child: Text('Capture Page')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggle,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        label: Text(_isRecording ? 'Stop' : 'Record'),
      ),
    );
  }
}