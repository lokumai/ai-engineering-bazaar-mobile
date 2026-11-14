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
        "fezCream" to "LauncherFezCream",
        "fezDark" to "LauncherFezDark",
        "antennaCream" to "LauncherAntennaCream",
        "antennaDark" to "LauncherAntennaDark",
        "beanieCream" to "LauncherBeanieCream",
        "beanieDark" to "LauncherBeanieDark",
        "domeCream" to "LauncherDomeCream",
        "domeDark" to "LauncherDomeDark",
        "mortarboardCream" to "LauncherMortarboardCream",
        "mortarboardDark" to "LauncherMortarboardDark",
        "tvCream" to "LauncherTvCream",
        "tvDark" to "LauncherTvDark",
        "turbanCream" to "LauncherTurbanCream",
        "turbanDark" to "LauncherTurbanDark",
        "earsCream" to "LauncherEarsCream",
        "earsDark" to "LauncherEarsDark",
        "wizardCream" to "LauncherWizardCream",
        "wizardDark" to "LauncherWizardDark",
        "topHatCream" to "LauncherTopHatCream",
        "topHatDark" to "LauncherTopHatDark",
        "visorCream" to "LauncherVisorCream",
        "visorDark" to "LauncherVisorDark",
        "crownCream" to "LauncherCrownCream",
        "crownDark" to "LauncherCrownDark",
    )

    /** Each icon's ground: the launch screen's colour and the window's behind the app until its first frame. */
    val grounds = mapOf(
        "fezCream" to R.color.ic_launcher_cream_background,
        "fezDark" to R.color.bazaar_page,
        "antennaCream" to R.color.ic_launcher_cream_background,
        "antennaDark" to R.color.bazaar_page,
        "beanieCream" to R.color.ic_launcher_cream_background,
        "beanieDark" to R.color.bazaar_page,
        "domeCream" to R.color.ic_launcher_cream_background,
        "domeDark" to R.color.bazaar_page,
        "mortarboardCream" to R.color.ic_launcher_cream_background,
        "mortarboardDark" to R.color.bazaar_page,
        "tvCream" to R.color.ic_launcher_cream_background,
        "tvDark" to R.color.bazaar_page,
        "turbanCream" to R.color.ic_launcher_cream_background,
        "turbanDark" to R.color.bazaar_page,
        "earsCream" to R.color.ic_launcher_cream_background,
        "earsDark" to R.color.bazaar_page,
        "wizardCream" to R.color.ic_launcher_cream_background,
        "wizardDark" to R.color.bazaar_page,
        "topHatCream" to R.color.ic_launcher_cream_background,
        "topHatDark" to R.color.bazaar_page,
        "visorCream" to R.color.ic_launcher_cream_background,
        "visorDark" to R.color.bazaar_page,
        "crownCream" to R.color.ic_launcher_cream_background,
        "crownDark" to R.color.bazaar_page,
    )

    /** Each icon's launch screen on Android 13 and later (values-v31/styles.xml), on its ground. */
    val launchThemes = mapOf(
        "fezCream" to R.style.LaunchTheme,
        "fezDark" to R.style.LaunchTheme_Dark,
        "antennaCream" to R.style.LaunchTheme,
        "antennaDark" to R.style.LaunchTheme_Dark,
        "beanieCream" to R.style.LaunchTheme,
        "beanieDark" to R.style.LaunchTheme_Dark,
        "domeCream" to R.style.LaunchTheme,
        "domeDark" to R.style.LaunchTheme_Dark,
        "mortarboardCream" to R.style.LaunchTheme,
        "mortarboardDark" to R.style.LaunchTheme_Dark,
        "tvCream" to R.style.LaunchTheme,
        "tvDark" to R.style.LaunchTheme_Dark,
        "turbanCream" to R.style.LaunchTheme,
        "turbanDark" to R.style.LaunchTheme_Dark,
        "earsCream" to R.style.LaunchTheme,
        "earsDark" to R.style.LaunchTheme_Dark,
        "wizardCream" to R.style.LaunchTheme,
        "wizardDark" to R.style.LaunchTheme_Dark,
        "topHatCream" to R.style.LaunchTheme,
        "topHatDark" to R.style.LaunchTheme_Dark,
        "visorCream" to R.style.LaunchTheme,
        "visorDark" to R.style.LaunchTheme_Dark,
        "crownCream" to R.style.LaunchTheme,
        "crownDark" to R.style.LaunchTheme_Dark,
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
     * next launch shows (the system keeps it; earlier versions show the default's cream one, then the window turns to
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
