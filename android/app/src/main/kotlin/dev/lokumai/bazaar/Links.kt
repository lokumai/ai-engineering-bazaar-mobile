package dev.lokumai.bazaar

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The links the phone hands the app (plan 17.2), on the channel lib/infrastructure/links/link_channel.dart listens to:
 * the site's pages its app links name (AndroidManifest.xml, the site's assetlinks.json) and the app's own scheme
 * `aibazaar://transfer`, which the site's transfer page offers.
 *
 * A link that comes before the Dart side asks waits; `ready` gives the ones waiting and from then on each comes as
 * `link`. The Dart side reads only the links it knows (SiteLink) and leaves the rest.
 *
 * A page of the site the app itself opens on the web (a module's "on the website" link) is one its app links claim, so
 * Android hands it back to the app; such a link goes on to a browser instead, as iOS opens it in Safari (plan 18.7).
 */
class Links(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/links"
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val waiting = mutableListOf<String>()
    private var ready = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    ready = true
                    result.success(waiting.toList())
                    waiting.clear()
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Hands the Dart side the link [intent] carries, when it is a view of one. */
    fun receive(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        // A task reopened from the recent apps carries the intent it was started with: that link was opened then.
        if ((intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) return
        val link = intent.dataString ?: return
        if (fromThisApp() && intent.data?.scheme == "https") return toBrowser(intent.data!!)
        if (ready) channel.invokeMethod("link", link) else waiting.add(link)
    }

    /** Whether the link was opened by this app itself, whose own app link brought it back here. */
    private fun fromThisApp(): Boolean {
        val referrer = activity.referrer ?: return false
        return referrer.scheme == "android-app" && referrer.host == activity.packageName
    }

    /** Opens [uri] in the phone's default browser, or in any browser but this app when there is no default. */
    private fun toBrowser(uri: Uri) {
        val pm = activity.packageManager
        val probe = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com")).addCategory(Intent.CATEGORY_BROWSABLE)
        val default = pm.resolveActivity(probe, PackageManager.MATCH_DEFAULT_ONLY)?.activityInfo?.packageName
        val browser = default?.takeIf { it != "android" && it != activity.packageName }
            ?: pm.queryIntentActivities(probe, 0).map { it.activityInfo.packageName }.firstOrNull { it != activity.packageName }
            ?: return
        val view = Intent(Intent.ACTION_VIEW, uri)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .setPackage(browser)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { activity.startActivity(view) }
    }

    fun close() {
        channel.setMethodCallHandler(null)
    }
}
