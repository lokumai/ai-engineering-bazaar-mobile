package dev.lokumai.bazaar

import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The links the phone hands the app (plan 17.2), on the channel lib/infrastructure/links/link_channel.dart listens to:
 * the site's pages its app links name (AndroidManifest.xml, the site's assetlinks.json) and the app's own scheme
 * `aibazaar://transfer`, which the site's transfer page offers.
 *
 * A link that comes before the Dart side asks waits; `ready` gives the ones waiting and from then on each comes as
 * `link`. The Dart side reads only the links it knows (SiteLink) and leaves the rest.
 */
class Links(messenger: BinaryMessenger) {
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
        if (ready) channel.invokeMethod("link", link) else waiting.add(link)
    }

    fun close() {
        channel.setMethodCallHandler(null)
    }
}
