package com.example.hold_that_thought;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import android.Manifest;
import android.content.pm.PackageManager;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class PermissionHelper implements MethodCallHandler {
    private static final String CHANNEL = "htt/permissions";
    private static final int REQUEST_NOTIFICATION_PERMISSION = 100;

    private final Context context;
    private Activity activity;
    private MethodChannel methodChannel;
    private Result pendingResult;

    public PermissionHelper(Context context) {
        this.context = context;
    }

    public static void registerWith(FlutterEngine flutterEngine, Context context) {
        MethodChannel channel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        );
        PermissionHelper helper = new PermissionHelper(context);
        channel.setMethodCallHandler(helper);
        helper.methodChannel = channel;
    }

    public void setActivity(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getAndroidSdkVersion":
                result.success(Build.VERSION.SDK_INT);
                break;

            case "requestNotificationPermission":
                if (Build.VERSION.SDK_INT >= 33) { // Android 13
                    pendingResult = result;
                    requestNotificationPermission();
                } else {
                    // Prior to Android 13, notifications didn't require runtime permission
                    result.success(true);
                }
                break;

            case "openNotificationSettings":
                openNotificationSettings();
                result.success(null);
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    private void requestNotificationPermission() {
        if (activity == null) {
            if (pendingResult != null) {
                pendingResult.error("UNAVAILABLE", "Activity is not available", null);
                pendingResult = null;
            }
            return;
        }

        if (Build.VERSION.SDK_INT >= 33) { // Android 13
            if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                        activity,
                        new String[]{Manifest.permission.POST_NOTIFICATIONS},
                        REQUEST_NOTIFICATION_PERMISSION
                );
            } else {
                if (pendingResult != null) {
                    pendingResult.success(true);
                    pendingResult = null;
                }
            }
        } else {
            if (pendingResult != null) {
                pendingResult.success(true);
                pendingResult = null;
            }
        }
    }

    public void handleRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == REQUEST_NOTIFICATION_PERMISSION && pendingResult != null) {
            boolean granted = grantResults.length > 0 &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED;

            pendingResult.success(granted);
            pendingResult = null;
        }
    }

    private void openNotificationSettings() {
        if (activity == null) return;

        Intent intent = new Intent();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
        } else {
            intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.addCategory(Intent.CATEGORY_DEFAULT);
            intent.setData(Uri.parse("package:" + context.getPackageName()));
        }
        activity.startActivity(intent);
    }
}
