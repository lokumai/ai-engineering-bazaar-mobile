package dev.lokumai.bazaar

import android.os.VibrationEffect
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Each touch feedback kind as one soft primitive ([Haptics.primitive], plan 18.12). */
class HapticsTest {
    @Test
    fun everyKindIsAPrimitiveTheSelectionATick() {
        assertEquals(VibrationEffect.Composition.PRIMITIVE_TICK, Haptics.primitive("selection")?.first)
        for (kind in listOf("light", "medium", "heavy")) {
            assertEquals(kind, VibrationEffect.Composition.PRIMITIVE_CLICK, Haptics.primitive(kind)?.first)
        }
    }

    @Test
    fun theTapsGrowWithTheirWeightAndStaySoft() {
        val scales = listOf("light", "medium", "heavy").map { Haptics.primitive(it)!!.second }
        assertEquals(scales.sorted(), scales)
        assertTrue("never the phone's full strength", Haptics.kinds.all { Haptics.primitive(it)!!.second <= 0.7f })
    }

    @Test
    fun anUnknownKindIsNone() {
        assertNull(Haptics.primitive("buzz"))
    }
}
