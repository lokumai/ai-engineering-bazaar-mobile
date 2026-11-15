package dev.lokumai.bazaar

import android.app.Activity
import android.content.Context
import android.os.Build

/**
 * The ground the app starts on, before Flutter draws: the page colour of the look the reader reads in, light or dark
 * (the owner, 2026-11-15), not the app icon's. The Dart side names the look on the channel
 * `dev.lokumai.bazaar/launch_ground` (lib/infrastructure/theme/launch_ground_channel.dart) on every launch and on every
 * choice; it is kept here for the next launch.
 *
 * Android 13 and later show the look's launch screen from the next launch ([apply]). Earlier versions always show the
 * manifest's, on the dark ground the app opens in until the reader chooses; the window then takes the look's ground
 * ([MainActivity.onCreate]).
 */
object LaunchGround {
    const val CHANNEL = "dev.lokumai.bazaar/launch_ground"

    private const val PREFERENCES = "launch_ground"
    private const val KEY = "look"

    /** Each look's name on the Dart side and its ground. */
    val grounds = mapOf("light" to R.color.ic_launcher_cream_background, "dark" to R.color.bazaar_page)

    /** Each look's launch screen on Android 13 and later (values-v31/styles.xml). */
    val launchThemes = mapOf("light" to R.style.LaunchTheme_Light, "dark" to R.style.LaunchTheme)

    /** The look last named: dark, the app's own until the reader chooses, before the Dart side named one. */
    fun current(context: Context): String =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(KEY, null)?.takeIf { it in grounds }
            ?: "dark"

    /** The ground of the look last named. */
    fun ground(context: Context): Int = grounds.getValue(current(context))

    /** Keeps [look] for the next launch and makes its launch screen the one the next launch shows. */
    fun apply(activity: Activity, look: String) {
        activity.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().putString(KEY, look).apply()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.splashScreen.setSplashScreenTheme(launchThemes.getValue(look))
        }
    }
}
