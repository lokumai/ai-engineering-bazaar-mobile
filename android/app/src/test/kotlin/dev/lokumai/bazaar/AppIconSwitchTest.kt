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
        // The manifest's launch screen is the default's, cream; the icons on the dark ground have a dark one.
        assertEquals(R.style.LaunchTheme, AppIconSwitch.launchThemes["fezCream"])
        assertEquals(R.style.LaunchTheme_Dark, AppIconSwitch.launchThemes["fezDark"])
    }

    @Test
    fun everyIconHasAGroundAndALaunchScreen() {
        assertEquals(AppIconSwitch.aliases.keys, AppIconSwitch.grounds.keys)
        assertEquals(AppIconSwitch.aliases.keys, AppIconSwitch.launchThemes.keys)
    }
}
