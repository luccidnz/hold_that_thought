package com.example.hold_that_thought

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var permissionHelper: PermissionHelper
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the recording service with Flutter
        RecordingService.registerWith(flutterEngine, applicationContext)
        
        // Register permission helper
        permissionHelper = PermissionHelper(applicationContext)
        permissionHelper.setActivity(this)
        PermissionHelper.registerWith(flutterEngine, applicationContext)
    }
    
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        permissionHelper.handleRequestPermissionsResult(requestCode, permissions, grantResults)
    }
    
    override fun onResume() {
        super.onResume()
        permissionHelper.setActivity(this)
    }
    
    override fun onPause() {
        super.onPause()
        permissionHelper.setActivity(null)
    }
}
