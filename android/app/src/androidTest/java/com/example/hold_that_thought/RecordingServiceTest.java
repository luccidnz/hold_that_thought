package com.example.hold_that_thought;

import android.content.Context;
import android.content.Intent;

import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.File;

import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class RecordingServiceTest {

    private Context context;
    private String testOutputPath;

    @Before
    public void setUp() {
        context = ApplicationProvider.getApplicationContext();
        File outputDir = context.getCacheDir();
        testOutputPath = new File(outputDir, "test_recording.m4a").getAbsolutePath();

        // Delete any existing test file
        File outputFile = new File(testOutputPath);
        if (outputFile.exists()) {
            outputFile.delete();
        }
    }

    @After
    public void tearDown() {
        // Stop any running service
        Intent stopIntent = new Intent(context, RecordingService.class);
        stopIntent.setAction("stop");
        context.startService(stopIntent);

        // Clean up test file
        File outputFile = new File(testOutputPath);
        if (outputFile.exists()) {
            outputFile.delete();
        }
    }

    @Test
    public void testRecordingServiceSmokeTest() throws Exception {
        // Start the recording service
        Intent intent = new Intent(context, RecordingService.class);
        intent.setAction("start");
        intent.putExtra("filePath", testOutputPath);
        context.startService(intent);

        // Wait for 5 seconds to simulate recording
        Thread.sleep(5000);

        // Stop the service
        Intent stopIntent = new Intent(context, RecordingService.class);
        stopIntent.setAction("stop");
        context.startService(stopIntent);

        // Wait for service to process the stop
        Thread.sleep(1000);

        // Verify that the file was created
        File outputFile = new File(testOutputPath);
        assertTrue("Recording file should exist", outputFile.exists());
        assertTrue("Recording file should have data", outputFile.length() > 0);
    }

    @Test
    public void testRecordingServiceWithLockScreen() throws Exception {
        // Start the recording service
        Intent intent = new Intent(context, RecordingService.class);
        intent.setAction("start");
        intent.putExtra("filePath", testOutputPath);
        context.startService(intent);

        // Simulate locking the screen
        Intent lockIntent = new Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS);
        context.sendBroadcast(lockIntent);

        // Wait for 30 seconds to simulate recording with locked screen
        Thread.sleep(30000);

        // Stop the service
        Intent stopIntent = new Intent(context, RecordingService.class);
        stopIntent.setAction("stop");
        context.startService(stopIntent);

        // Wait for service to process the stop
        Thread.sleep(1000);

        // Verify that the file was created
        File outputFile = new File(testOutputPath);
        assertTrue("Recording file should exist after lock screen", outputFile.exists());
        assertTrue("Recording file should have data after lock screen", outputFile.length() > 0);
    }
}
