package dev.lokumai.bazaar

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/**
 * The app icon the reader chose in Settings (lib/shared/app_icon/): one launcher entry (`activity-alias` in the
 * manifest) for each icon, exactly one enabled. The Dart side names the icon on the channel
 * `dev.lokumai.bazaar/app_icon`; the entries change when the app goes to the background ([MainActivity.onStop]), since
 * some launchers close an app whose launcher entry changes while it is in front.
 */
object AppIconSwitch {
    const val CHANNEL = "dev.lokumai.bazaar/app_icon"

    /** Each icon's name on the Dart side and its launcher entry; the first is the manifest's enabled default. */
    val aliases = linkedMapOf(
        "dark" to "LauncherDark",
        "cream" to "LauncherCream",
        "noir" to "LauncherNoir",
        "ink" to "LauncherInk",
        "nightGold" to "LauncherNightGold",
        "nightSea" to "LauncherNightSea",
    )

    /** Each icon's ground: the launch screen's colour and the window's behind the app until its first frame. */
    val grounds = mapOf(
        "dark" to R.color.bazaar_page,
        "cream" to R.color.ic_launcher_cream_background,
        "noir" to R.color.ic_launcher_noir_background,
        "ink" to R.color.ic_launcher_ink_background,
        "nightGold" to R.color.ic_launcher_night_gold_background,
        "nightSea" to R.color.ic_launcher_night_sea_background,
    )

    /** Each icon's launch screen on Android 13 and later (values-v31/styles.xml), on its ground. */
    val launchThemes = mapOf(
        "dark" to R.style.LaunchTheme,
        "cream" to R.style.LaunchTheme_Cream,
        "noir" to R.style.LaunchTheme_Noir,
        "ink" to R.style.LaunchTheme_Ink,
        "nightGold" to R.style.LaunchTheme_NightGold,
        "nightSea" to R.style.LaunchTheme_NightSea,
    )

    /**
     * The launcher entries to turn on (true) or off (false) so that only [chosen]'s is on, given the ones on now
     * ([enabled]); nothing for an entry already right, so a launch with the same icon changes nothing.
     */
    fun changes(enabled: Set<String>, chosen: String): Map<String, Boolean> {
        val target = aliases.getValue(chosen)
        return aliases.values
            .filter { (it == target) != (it in enabled) }
            .associateWith { it == target }
    }

    /** The icon whose launcher entry is enabled: the default when none is, which the manifest never leaves. */
    fun current(context: Context): String {
        val pm = context.packageManager
        return aliases.entries.firstOrNull { (_, alias) -> isEnabled(pm, component(context, alias), alias) }?.key
            ?: aliases.keys.first()
    }

    /**
     * Makes [chosen]'s launcher entry the only one enabled, and on Android 13 and later its launch screen the one the
     * next launch shows (the system keeps it; earlier versions show the default's dark one, then the window turns to
     * the icon's ground, [MainActivity.onCreate]).
     */
    fun apply(activity: Activity, chosen: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.splashScreen.setSplashScreenTheme(launchThemes.getValue(chosen))
        }
        val context: Context = activity
        val pm = context.packageManager
        val enabled = aliases.values.filterTo(mutableSetOf()) { isEnabled(pm, component(context, it), it) }
        // The chosen entry goes on before the others go off, so there is always one in the launcher.
        for ((alias, on) in changes(enabled, chosen).entries.sortedByDescending { it.value }) {
            pm.setComponentEnabledSetting(
                component(context, alias),
                if (on) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun component(context: Context, alias: String) = ComponentName(context.packageName, "${context.packageName}.$alias")

    private fun isEnabled(pm: PackageManager, component: ComponentName, alias: String) =
        when (pm.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> alias == aliases.values.first()
            else -> false
        }
}
