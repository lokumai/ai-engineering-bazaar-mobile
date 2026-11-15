package dev.lokumai.bazaar

import org.junit.Assert.assertEquals
import org.junit.Test

/** The launcher entries [AppIconSwitch.changes] turns on and off. */
class AppIconSwitchTest {
    @Test
    fun turnsTheChosenEntryOnAndTheEnabledOneOff() {
        assertEquals(
            mapOf("LauncherFezDark" to false, "LauncherWizardCream" to true),
            AppIconSwitch.changes(setOf("LauncherFezDark"), "wizardCream"),
        )
    }

    @Test
    fun changesNothingWhenTheChosenEntryIsTheOnlyOneOn() {
        assertEquals(emptyMap<String, Boolean>(), AppIconSwitch.changes(setOf("LauncherTvCream"), "tvCream"))
    }

    @Test
    fun turnsOffEveryOtherEntryThatIsOn() {
        assertEquals(
            mapOf("LauncherFezDark" to true, "LauncherFezCream" to false, "LauncherCrownDark" to false),
            AppIconSwitch.changes(setOf("LauncherFezCream", "LauncherCrownDark"), "fezDark"),
        )
    }

    @Test
    fun theFezOnTheCreamGroundIsTheDefaultTheManifestEnables() {
        assertEquals("fezCream", AppIconSwitch.aliases.keys.first())
    }
}
