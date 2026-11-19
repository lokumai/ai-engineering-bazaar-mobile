package dev.lokumai.bazaar

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The phone's share sheet (plan 17.3), on the channel lib/infrastructure/share/share_channel.dart calls: `share` with a
 * text, which the phone offers to its apps. The reader picks the app; nothing is sent until then.
 */
class ShareSheet(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/share"
    }

    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            val text = call.arguments as? String
            when {
                call.method != "share" -> result.notImplemented()
                text.isNullOrEmpty() -> result.error("no-text", null, null)
                else -> try {
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    activity.startActivity(Intent.createChooser(send, null))
                    result.success(null)
                } catch (error: ActivityNotFoundException) {
                    result.error("no-sheet", error.message, null)
                }
            }
        }
    }

    fun close() {
        channel.setMethodCallHandler(null)
    }
}
