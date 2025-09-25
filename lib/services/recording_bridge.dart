import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class RecordingBridge {
  static const MethodChannel _channel = MethodChannel('htt/recording');
  static final RecordingBridge _instance = RecordingBridge._internal();
  
  // Stream controller for events from the native service
  final StreamController<RecordingEvent> _eventController = 
      StreamController<RecordingEvent>.broadcast();
  
  // Public stream for consumers to listen to
  Stream<RecordingEvent> get events => _eventController.stream;
  
  factory RecordingBridge() {
    return _instance;
  }
  
  RecordingBridge._internal() {
    // Set up method call handler for receiving events from native side
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  // Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onServiceEvent') {
      final Map<String, dynamic> eventData = Map<String, dynamic>.from(call.arguments);
      final String event = eventData['event'];
      final dynamic data = eventData['data'];
      
      switch (event) {
        case 'onRecordingStarted':
          _eventController.add(RecordingEvent.started());
          break;
        case 'onRecordingCompleted':
          final String path = data['path'];
          final int duration = data['duration'];
          _eventController.add(RecordingEvent.completed(path, duration));
          break;
        case 'onError':
          _eventController.add(RecordingEvent.error(data.toString()));
          break;
      }
    }
    return null;
  }
  
  /// Start recording in foreground service mode
  /// 
  /// [filePath] must be the full path to save the recording
  Future<bool> startForeground(String filePath) async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>(
        'startRecording', 
        {'filePath': filePath}
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start foreground recording: ${e.message}');
      return false;
    }
  }
  
  /// Stop the foreground recording service
  Future<bool> stopForeground() async {
    if (!Platform.isAndroid) {
      return true; // Not needed on other platforms
    }
    
    try {
      final result = await _channel.invokeMethod<bool>('stopRecording');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to stop foreground recording: ${e.message}');
      return false;
    }
  }
  
  /// Check if recording is currently active
  Future<bool> isRecording() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>('isRecording');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check recording status: ${e.message}');
      return false;
    }
  }
  
  /// Check if the device supports foreground service
  Future<bool> isSupported() async {
    return Platform.isAndroid;
  }
  
  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}

/// Event class for recording service events
class RecordingEvent {
  final RecordingEventType type;
  final String? path;
  final int? duration;
  final String? error;
  
  RecordingEvent.started() 
      : type = RecordingEventType.started,
        path = null,
        duration = null,
        error = null;
        
  RecordingEvent.completed(this.path, this.duration) 
      : type = RecordingEventType.completed,
        error = null;
        
  RecordingEvent.error(this.error) 
      : type = RecordingEventType.error,
        path = null,
        duration = null;
}

/// Types of recording events
enum RecordingEventType {
  started,
  completed,
  error
}
