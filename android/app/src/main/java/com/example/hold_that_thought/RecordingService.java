package com.example.hold_that_thought;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import android.app.Service;
import android.media.MediaRecorder;
import android.util.Log;

public class RecordingService extends Service implements MethodChannel.MethodCallHandler {
    private static final String TAG = "RecordingService";
    private static final String CHANNEL_NAME = "htt/recording";
    private static final int NOTIFICATION_ID = 1001;
    private static final String NOTIFICATION_CHANNEL_ID = "htt_recording_channel";
    
    private MediaRecorder mediaRecorder;
    private String outputFilePath;
    private long startTimeMillis;
    private final AtomicBoolean isRecording = new AtomicBoolean(false);
    private MethodChannel methodChannel;
    private Handler mainHandler;
    
    @Override
    public void onCreate() {
        super.onCreate();
        mainHandler = new Handler(Looper.getMainLooper());
        
        // Create notification channel (required for Android 8.0+)
        createNotificationChannel();
    }
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && intent.getAction() != null) {
            switch (intent.getAction()) {
                case "start":
                    String filePath = intent.getStringExtra("filePath");
                    startRecording(filePath);
                    break;
                case "stop":
                    stopRecording();
                    break;
                default:
                    Log.e(TAG, "Unknown action: " + intent.getAction());
                    break;
            }
        }
        
        return START_STICKY;
    }
    
    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
    
    @Override
    public void onDestroy() {
        stopRecording();
        super.onDestroy();
    }
    
    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "HTT Recording",
                    NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Hold That Thought recording service");
            channel.setShowBadge(false);
            
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(channel);
            }
        }
    }
    
    private Notification createNotification() {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_IMMUTABLE
        );
        
        // Create "Stop" action
        Intent stopIntent = new Intent(this, RecordingService.class);
        stopIntent.setAction("stop");
        PendingIntent stopPendingIntent = PendingIntent.getService(
                this,
                0,
                stopIntent,
                PendingIntent.FLAG_IMMUTABLE
        );
        
        // Calculate recording duration
        long durationSeconds = (System.currentTimeMillis() - startTimeMillis) / 1000;
        String durationText = String.format("%02d:%02d", durationSeconds / 60, durationSeconds % 60);
        
        return new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("Recording in progress")
                .setContentText("Duration: " + durationText)
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentIntent(pendingIntent)
                .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
                .setOngoing(true)
                .build();
    }
    
    private void startRecording(String filePath) {
        if (isRecording.get()) {
            Log.w(TAG, "Recording already in progress");
            return;
        }
        
        outputFilePath = filePath;
        
        try {
            mediaRecorder = new MediaRecorder();
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
            mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);
            mediaRecorder.setAudioEncodingBitRate(128000);
            mediaRecorder.setAudioSamplingRate(44100);
            mediaRecorder.setOutputFile(outputFilePath);
            
            mediaRecorder.prepare();
            mediaRecorder.start();
            
            startTimeMillis = System.currentTimeMillis();
            isRecording.set(true);
            
            // Start as a foreground service with notification
            startForeground(NOTIFICATION_ID, createNotification());
            
            // Update notification periodically
            startNotificationUpdates();
            
            // Notify Flutter that recording has started
            notifyFlutter("onRecordingStarted", null);
            
            Log.i(TAG, "Recording started: " + outputFilePath);
        } catch (Exception e) {
            Log.e(TAG, "Failed to start recording", e);
            cleanupRecorder();
            notifyFlutter("onError", e.getMessage());
        }
    }
    
    private void stopRecording() {
        if (!isRecording.getAndSet(false)) {
            return;
        }
        
        try {
            if (mediaRecorder != null) {
                mediaRecorder.stop();
                mediaRecorder.release();
                mediaRecorder = null;
                
                // Calculate final duration
                long duration = System.currentTimeMillis() - startTimeMillis;
                
                // Notify Flutter that recording has stopped
                Map<String, Object> data = new HashMap<>();
                data.put("path", outputFilePath);
                data.put("duration", duration);
                notifyFlutter("onRecordingCompleted", data);
                
                Log.i(TAG, "Recording stopped: " + outputFilePath + ", duration: " + duration + "ms");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error stopping recording", e);
            notifyFlutter("onError", e.getMessage());
        } finally {
            cleanupRecorder();
            stopForeground(true);
            stopSelf();
        }
    }
    
    private void cleanupRecorder() {
        try {
            if (mediaRecorder != null) {
                mediaRecorder.release();
                mediaRecorder = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error cleaning up recorder", e);
        }
    }
    
    private void startNotificationUpdates() {
        mainHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (isRecording.get()) {
                    // Update the notification
                    NotificationManager notificationManager = 
                            (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
                    if (notificationManager != null) {
                        notificationManager.notify(NOTIFICATION_ID, createNotification());
                    }
                    
                    // Schedule the next update
                    mainHandler.postDelayed(this, 1000);
                }
            }
        }, 1000);
    }
    
    private void notifyFlutter(String event, Object data) {
        if (methodChannel != null) {
            Map<String, Object> eventData = new HashMap<>();
            eventData.put("event", event);
            eventData.put("data", data);
            
            mainHandler.post(() -> methodChannel.invokeMethod("onServiceEvent", eventData));
        }
    }
    
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "startRecording":
                String filePath = call.argument("filePath");
                if (filePath != null) {
                    Intent intent = new Intent(this, RecordingService.class);
                    intent.setAction("start");
                    intent.putExtra("filePath", filePath);
                    startService(intent);
                    result.success(true);
                } else {
                    result.error("INVALID_ARGUMENT", "File path is required", null);
                }
                break;
                
            case "stopRecording":
                Intent intent = new Intent(this, RecordingService.class);
                intent.setAction("stop");
                startService(intent);
                result.success(true);
                break;
                
            case "isRecording":
                result.success(isRecording.get());
                break;
                
            default:
                result.notImplemented();
                break;
        }
    }
    
    // Method to register the service with Flutter
    public static void registerWith(FlutterEngine flutterEngine, Context context) {
        MethodChannel channel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL_NAME
        );
        
        RecordingService service = new RecordingService();
        service.methodChannel = channel;
        channel.setMethodCallHandler(service);
    }
}
