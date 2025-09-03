import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'services/recording_bridge.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});
  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final _rec = AudioRecorder(); // record v6 API
  final _recordingBridge = RecordingBridge();
  bool _isRecording = false;
  StreamSubscription? _recordingEventsSub;

  @override
  void initState() {
    super.initState();
    unawaited(_initAudio());

    // Listen to recording events from the native side
    _recordingEventsSub = _recordingBridge.events.listen((event) {
      switch (event.type) {
        case RecordingEventType.error:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recording error: ${event.error}'))
            );
          }
          setState(() => _isRecording = false);
          break;

        case RecordingEventType.completed:
          setState(() => _isRecording = false);
          break;

        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _recordingEventsSub?.cancel();
    super.dispose();
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
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Request permissions first
      final has = await _rec.hasPermission();
      if (!has) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required'))
          );
        }
        return;
      }

      // Prepare recording path
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/thought_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // For Android: start foreground service first
      if (Platform.isAndroid) {
        // Check notification permission on Android 13+
        if (await _shouldRequestNotificationPermission()) {
          final granted = await _requestNotificationPermission();
          if (!granted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications permission required for background recording'),
                  action: SnackBarAction(
                    label: 'Settings',
                    onPressed: _openNotificationSettings,
                  ),
                )
              );
            }
            return;
          }
        }

        // Start foreground service
        final success = await _recordingBridge.startForeground(path);
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to start recording service'))
            );
          }
          return;
        }
      }

      // Start actual recording
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
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e'))
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Stop the actual recording
      final path = await _rec.stop();
      debugPrint('stopped → $path');

      // For Android: stop foreground service
      if (Platform.isAndroid) {
        await _recordingBridge.stopForeground();
      }

      setState(() => _isRecording = false);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e'))
        );
      }
    }
  }

  // Helper method to check if we need to request notification permission
  // Required on Android 13+ (SDK 33+)
  Future<bool> _shouldRequestNotificationPermission() async {
    if (!Platform.isAndroid) return false;

    // This is a simplified check - in production you'd use
    // a plugin like permission_handler to properly check permissions
    try {
      // For demonstration - this would normally be handled by permission_handler
      const platform = MethodChannel('htt/permissions');
      final sdkVersion = await platform.invokeMethod<int>('getAndroidSdkVersion') ?? 0;
      return sdkVersion >= 33; // Android 13
    } catch (e) {
      debugPrint('Error checking SDK version: $e');
      return false;
    }
  }

  // Helper method to request notification permission
  Future<bool> _requestNotificationPermission() async {
    try {
      // For demonstration - this would normally be handled by permission_handler
      const platform = MethodChannel('htt/permissions');
      return await platform.invokeMethod<bool>('requestNotificationPermission') ?? false;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Helper method to open notification settings
  void _openNotificationSettings() {
    try {
      // For demonstration - this would normally be handled by permission_handler
      const platform = MethodChannel('htt/permissions');
      platform.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
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