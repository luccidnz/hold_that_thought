package com.holdthatthought

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ExampleInstrumentedTest {
    @Test
    fun useAppContext() {
        val pkg = InstrumentationRegistry.getInstrumentation().targetContext.packageName
        // Be permissive across debug/release/test package name variants:
        assertTrue("Unexpected package name: $pkg", pkg.contains("hold_that_thought") || pkg.contains("holdthatthought"))
    }
}
