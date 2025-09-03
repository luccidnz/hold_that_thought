package com.holdthatthought

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ForegroundServiceSmokeTest {
    @Test
    fun startAndStopRecordingService() {
        val ctx = ApplicationProvider.getApplicationContext<Context>()
        val start = Intent(ctx, RecordingService::class.java).apply {
            action = "ACTION_START_FOREGROUND"
        }
        val comp = ctx.startForegroundService(start)
        assertNotNull("Service component should resolve", comp)
        Thread.sleep(1500)  // give it time to init and post notification
        ctx.stopService(Intent(ctx, RecordingService::class.java))
    }
}
