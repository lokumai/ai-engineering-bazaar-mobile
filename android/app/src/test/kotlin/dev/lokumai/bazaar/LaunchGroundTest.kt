package dev.lokumai.bazaar

import org.junit.Assert.assertEquals
import org.junit.Test

/** The launch screen of each look the Dart side names ([LaunchGround]). */
class LaunchGroundTest {
    @Test
    fun theManifestsLaunchScreenIsTheLightLooks() {
        // The app opens light until the reader chooses (the owner, 2026-11-16), so the manifest's launch screen is on
        // the cream ground.
        assertEquals(R.style.LaunchTheme, LaunchGround.launchThemes["light"])
        assertEquals(R.color.ic_launcher_cream_background, LaunchGround.grounds["light"])
    }

    @Test
    fun theDarkLookHasItsDarkLaunchScreen() {
        assertEquals(R.style.LaunchTheme_Dark, LaunchGround.launchThemes["dark"])
        assertEquals(R.color.bazaar_page, LaunchGround.grounds["dark"])
    }

    @Test
    fun everyLookHasAGroundAndALaunchScreen() {
        assertEquals(setOf("light", "dark"), LaunchGround.grounds.keys)
        assertEquals(LaunchGround.grounds.keys, LaunchGround.launchThemes.keys)
    }
}
