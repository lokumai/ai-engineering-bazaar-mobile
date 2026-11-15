package dev.lokumai.bazaar

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

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
     * Makes [chosen]'s launcher entry the only one enabled. The launch screen does not follow the icon but the reader's
     * look ([LaunchGround]).
     */
    fun apply(activity: Activity, chosen: String) {
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
