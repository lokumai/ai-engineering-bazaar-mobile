package dev.lokumai.bazaar

import org.junit.Assert.assertEquals
import org.junit.Test

/** The launch screen of each look the Dart side names ([LaunchGround]). */
class LaunchGroundTest {
    @Test
    fun theManifestsLaunchScreenIsTheDarkLooks() {
        // The app opens dark until the reader chooses, so the manifest's launch screen is on the dark ground.
        assertEquals(R.style.LaunchTheme, LaunchGround.launchThemes["dark"])
        assertEquals(R.color.bazaar_page, LaunchGround.grounds["dark"])
    }

    @Test
    fun theLightLookHasItsCreamLaunchScreen() {
        assertEquals(R.style.LaunchTheme_Light, LaunchGround.launchThemes["light"])
        assertEquals(R.color.ic_launcher_cream_background, LaunchGround.grounds["light"])
    }

    @Test
    fun everyLookHasAGroundAndALaunchScreen() {
        assertEquals(setOf("light", "dark"), LaunchGround.grounds.keys)
        assertEquals(LaunchGround.grounds.keys, LaunchGround.launchThemes.keys)
    }
}
