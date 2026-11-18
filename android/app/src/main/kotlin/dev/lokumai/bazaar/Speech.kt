package dev.lokumai.bazaar

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * The phone's own voice, which reads a module aloud (plan 15.1), on the channel lib/infrastructure/speech/phone_speech.dart
 * calls: `canSpeak` with a language, `speak` with an id, the words, the tag and the rate, and `stop`. Each speak's id
 * goes back in `done` once its words are said, cut or failed. The engine starts on the first call and is shut down with
 * the activity; nothing leaves the phone.
 */
class Speech(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/speech"

        /** Whether [locale] has a voice by the engine's own answer to [TextToSpeech.isLanguageAvailable]. */
        fun available(answer: Int): Boolean = answer >= TextToSpeech.LANG_AVAILABLE
    }

    private val channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
    private val main = Handler(Looper.getMainLooper())
    private var engine: TextToSpeech? = null

    /** The engine's start, once it answers: null until then. */
    private var started: Int? = null
    private val waiting = mutableListOf<() -> Unit>()

    private val progress = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) = Unit

        override fun onDone(utteranceId: String?) = done(utteranceId)

        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) = done(utteranceId)

        override fun onError(utteranceId: String?, errorCode: Int) = done(utteranceId)

        override fun onStop(utteranceId: String?, interrupted: Boolean) = done(utteranceId)
    }

    private fun done(utteranceId: String?) {
        val id = utteranceId?.toIntOrNull() ?: return
        main.post { channel.invokeMethod("done", id) }
    }

    /** Runs [action] on the main thread once the engine has started, starting it on the first call. */
    private fun whenStarted(action: (TextToSpeech?) -> Unit) {
        if (started != null) return action(engine.takeIf { started == TextToSpeech.SUCCESS })
        waiting.add { action(engine.takeIf { started == TextToSpeech.SUCCESS }) }
        if (engine != null) return
        engine = TextToSpeech(context.applicationContext) { status ->
            main.post {
                started = status
                engine?.setOnUtteranceProgressListener(progress)
                waiting.forEach { it() }
                waiting.clear()
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canSpeak" -> {
                val tag = call.argument<String>("tag") ?: return result.error("no-tag", null, null)
                whenStarted { tts ->
                    result.success(tts != null && available(tts.isLanguageAvailable(Locale.forLanguageTag(tag))))
                }
            }
            "speak" -> {
                val id = call.argument<Int>("id") ?: return result.error("no-id", null, null)
                val text = call.argument<String>("text") ?: ""
                val tag = call.argument<String>("tag") ?: return result.error("no-tag", null, null)
                val rate = call.argument<Double>("rate") ?: 1.0
                whenStarted { tts ->
                    if (tts == null || !available(tts.setLanguage(Locale.forLanguageTag(tag)))) {
                        return@whenStarted result.success(false)
                    }
                    tts.setSpeechRate(rate.toFloat())
                    // A flush cuts the words being said, whose id then comes back as done.
                    result.success(tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, id.toString()) == TextToSpeech.SUCCESS)
                }
            }
            "stop" -> {
                engine?.stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Shuts the engine down with the activity. */
    fun close() {
        channel.setMethodCallHandler(null)
        engine?.shutdown()
        engine = null
        started = null
        waiting.clear()
    }
}
