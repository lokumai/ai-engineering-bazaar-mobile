package dev.lokumai.bazaar

import org.junit.Assert.assertEquals
import org.junit.Test

/** The launcher entries [AppIconSwitch.changes] turns on and off. */
class AppIconSwitchTest {
    @Test
    fun turnsTheChosenEntryOnAndTheEnabledOneOff() {
        assertEquals(
            mapOf("LauncherDark" to false, "LauncherNoir" to true),
            AppIconSwitch.changes(setOf("LauncherDark"), "noir"),
        )
    }

    @Test
    fun changesNothingWhenTheChosenEntryIsTheOnlyOneOn() {
        assertEquals(emptyMap<String, Boolean>(), AppIconSwitch.changes(setOf("LauncherNightSea"), "nightSea"))
    }

    @Test
    fun turnsOffEveryOtherEntryThatIsOn() {
        assertEquals(
            mapOf("LauncherDark" to true, "LauncherCream" to false, "LauncherInk" to false),
            AppIconSwitch.changes(setOf("LauncherCream", "LauncherInk"), "dark"),
        )
    }
}
