package com.holdthatthought

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ForegroundServiceSmokeTest {
    @Test
    fun verifyPackageName() {
        val ctx = ApplicationProvider.getApplicationContext<Context>()
        // Be permissive across debug/release/test package name variants:
        assertTrue("Unexpected package name: ${ctx.packageName}", 
                  ctx.packageName.contains("hold_that_thought") || 
                  ctx.packageName.contains("holdthatthought"))
    }
}
