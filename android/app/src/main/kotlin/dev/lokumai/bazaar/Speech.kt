package dev.lokumai.bazaar

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * The phone's own voice, which reads a module aloud (plan 15), on the channel lib/infrastructure/speech/phone_speech.dart
 * calls: `canSpeak` with a language, `speak` with an id, the texts, the tag and the rate, and `stop`. A speak queues
 * every text with the engine at once, in the best voice installed for the language, so the reading goes on with the
 * screen off (the owner, 2026-11-18). Each text's start goes back in `part` with the speak's id and its place, and the
 * id in `done` once the last is said, or they are cut or failed. The engine starts on the first call and is shut down
 * with the activity; nothing leaves the phone.
 */
class Speech(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/speech"

        /** Whether [locale] has a voice by the engine's own answer to [TextToSpeech.isLanguageAvailable]. */
        fun available(answer: Int): Boolean = answer >= TextToSpeech.LANG_AVAILABLE

        /** The utterance id of the text at [index] of the speak [id]. */
        fun utterance(id: Int, index: Int, last: Boolean): String = "$id:$index:${if (last) 1 else 0}"

        /** The speak's id, the text's place and whether it is the last, from an utterance id; null for another's. */
        fun parse(utterance: String?): Triple<Int, Int, Boolean>? {
            val parts = utterance?.split(':') ?: return null
            if (parts.size != 3) return null
            val id = parts[0].toIntOrNull() ?: return null
            val index = parts[1].toIntOrNull() ?: return null
            return Triple(id, index, parts[2] == "1")
        }

        /**
         * The place in [voices] of the best one for [language] and [country]: installed and needing no network, then
         * of the country, then of the highest quality, then the quickest; null when none speaks the language.
         */
        fun best(voices: List<VoiceFacts>, language: String, country: String): Int? =
            voices.withIndex()
                .filter { (_, voice) -> voice.language == language && voice.installed && !voice.network }
                .maxWithOrNull(
                    compareBy<IndexedValue<VoiceFacts>>(
                        { it.value.country.equals(country, ignoreCase = true) },
                        { it.value.quality },
                        { -it.value.latency },
                    ),
                )?.index
    }

    /** What [best] weighs of a voice, apart from the framework's [Voice]. */
    data class VoiceFacts(
        val language: String,
        val country: String,
        val quality: Int,
        val latency: Int,
        val network: Boolean,
        val installed: Boolean,
    )

    private val channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
    private val main = Handler(Looper.getMainLooper())
    private var engine: TextToSpeech? = null

    /** The engine's start, once it answers: null until then. */
    private var started: Int? = null
    private val waiting = mutableListOf<() -> Unit>()

    /** The speaks whose end has been told, so a cut queue tells it once. */
    private val ended = mutableSetOf<Int>()

    private val progress = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {
            val (id, index, _) = parse(utteranceId) ?: return
            main.post { channel.invokeMethod("part", mapOf("id" to id, "index" to index)) }
        }

        override fun onDone(utteranceId: String?) {
            val (id, _, last) = parse(utteranceId) ?: return
            if (last) done(id)
        }

        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) = cut(utteranceId)

        override fun onError(utteranceId: String?, errorCode: Int) = cut(utteranceId)

        override fun onStop(utteranceId: String?, interrupted: Boolean) = cut(utteranceId)
    }

    private fun cut(utteranceId: String?) {
        val (id, _, _) = parse(utteranceId) ?: return
        done(id)
    }

    private fun done(id: Int) {
        main.post { if (ended.add(id)) channel.invokeMethod("done", id) }
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

    /** Sets the best voice installed for [locale] on [tts], or leaves the engine's own. */
    private fun pickVoice(tts: TextToSpeech, locale: Locale) {
        val voices = runCatching { tts.voices?.toList() }.getOrNull() ?: return
        val facts = voices.map { voice: Voice ->
            VoiceFacts(
                language = voice.locale.language,
                country = voice.locale.country,
                quality = voice.quality,
                latency = voice.latency,
                network = voice.isNetworkConnectionRequired,
                installed = !voice.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED),
            )
        }
        val best = best(facts, locale.language, locale.country) ?: return
        runCatching { tts.voice = voices[best] }
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
                val texts = call.argument<List<String>>("texts") ?: emptyList()
                val tag = call.argument<String>("tag") ?: return result.error("no-tag", null, null)
                val rate = call.argument<Double>("rate") ?: 1.0
                whenStarted { tts ->
                    val locale = Locale.forLanguageTag(tag)
                    if (tts == null || texts.isEmpty() || !available(tts.setLanguage(locale))) {
                        return@whenStarted result.success(false)
                    }
                    pickVoice(tts, locale)
                    tts.setSpeechRate(rate.toFloat())
                    // The first flushes the words being said, whose speak then comes back as done; the rest queue.
                    var queued = true
                    texts.forEachIndexed { index, text ->
                        val mode = if (index == 0) TextToSpeech.QUEUE_FLUSH else TextToSpeech.QUEUE_ADD
                        val utterance = utterance(id, index, index == texts.size - 1)
                        queued = queued && tts.speak(text, mode, null, utterance) == TextToSpeech.SUCCESS
                    }
                    result.success(queued)
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
