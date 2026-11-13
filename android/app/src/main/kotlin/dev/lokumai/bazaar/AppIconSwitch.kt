package dev.lokumai.bazaar

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
        "dark" to "LauncherDark",
        "cream" to "LauncherCream",
        "noir" to "LauncherNoir",
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

    /** Makes [chosen]'s launcher entry the only one enabled. */
    fun apply(context: Context, chosen: String) {
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
