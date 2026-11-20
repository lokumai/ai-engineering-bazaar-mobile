package dev.lokumai.bazaar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
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
 * calls: `canSpeak` with a language, `speak` with an id, the texts, the tag, the rate and the module's title, and
 * `stop`. A speak queues every text with the engine at once, in the best voice installed for the language, so the
 * reading goes on with the screen off (the owner, 2026-11-18). Each text's start goes back in `part` with the speak's id
 * and its place, and the id in `done` once the last is said, or they are cut or failed. The engine starts on the first
 * call and is shut down with the activity; nothing leaves the phone.
 *
 * As on iOS (plan 18): ListenService keeps the app running while it reads; the reading takes the sound for itself, so
 * other sound pauses while it speaks, as on iOS since plan 19.8 (plan 20.11); a short pause follows each text; a text
 * longer than the engine takes is said in pieces; and when another app takes the sound for itself, as a call does, the
 * reader presses Pause on the notice, or the headphones are taken off (plan 20.3), the reading stops and `interrupted`
 * tells the Dart side, which pauses where it was.
 *
 * The Dart side names the reading in `show` (its title and whether it plays, or null once it ends), which a
 * MediaSession holds, so the headphones' buttons and the lock screen's controls (where the notice may show) reach the
 * player: `control` `pause` or `play` (plan 19.8). The service starts with the speak itself, before the engine answers,
 * so a reader who leaves the app at once keeps the reading (plan 19.9); and while another app holds the sound, as a call
 * does, a speak is not said but comes back as interrupted, so the player waits on its part (plan 19.10).
 */
class Speech(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/speech"

        /** The pause after each text, as iOS's `postUtteranceDelay`. */
        const val GAP_MS = 150L

        /** How long other sound waits after the last word before it comes back up, as on iOS. */
        const val RELEASE_MS = 600L

        /** Whether [locale] has a voice by the engine's own answer to [TextToSpeech.isLanguageAvailable]. */
        fun available(answer: Int): Boolean = answer >= TextToSpeech.LANG_AVAILABLE

        /** The utterance id of piece [piece] of [pieces] of the text at [index] of the speak [id]. */
        fun utterance(id: Int, index: Int, last: Boolean, piece: Int = 0, pieces: Int = 1): String =
            "$id:$index:${if (last) 1 else 0}:$piece:$pieces"

        /** What an utterance id names; null for another's, such as the pause after a text. */
        fun parse(utterance: String?): Part? {
            val parts = utterance?.split(':') ?: return null
            if (parts.size != 5) return null
            val numbers = listOf(parts[0], parts[1], parts[3], parts[4]).map { it.toIntOrNull() ?: return null }
            return Part(numbers[0], numbers[1], parts[2] == "1", numbers[2], numbers[3])
        }

        /**
         * [text] cut into pieces of at most [max] characters, each ending at a sentence's end where one falls in the
         * second half of the piece, else at a space, else where it must; one piece when it fits. Android's engine
         * refuses a text longer than its `getMaxSpeechInputLength` (4000), and a list or a callout is one text.
         */
        fun pieces(text: String, max: Int): List<String> {
            if (text.length <= max) return listOf(text)
            val out = mutableListOf<String>()
            var rest = text
            while (rest.length > max) {
                val window = rest.substring(0, max)
                val sentence = Regex("""[.!?؟۔…:;]\s""").findAll(window).lastOrNull()?.range?.last
                val space = window.lastIndexOf(' ')
                val cut = when {
                    sentence != null && sentence >= max / 2 -> sentence
                    space >= max / 2 -> space
                    else -> max
                }
                out.add(rest.substring(0, cut).trim())
                rest = rest.substring(cut).trimStart()
            }
            if (rest.isNotBlank()) out.add(rest)
            return out.filter { it.isNotEmpty() }
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

    /** A piece of a text: the speak [id], the text's place [index], whether it is the [last] text, and its piece. */
    data class Part(val id: Int, val index: Int, val last: Boolean, val piece: Int, val pieces: Int) {
        /** The text's first piece, whose start is the text's. */
        val starts get() = piece == 0

        /** The text's last piece, whose end is the text's. */
        val ends get() = piece == pieces - 1
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

    /** The speak being read, if any. */
    private var current: Int? = null

    private val audio = context.getSystemService(AudioManager::class.java)
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    /**
     * A short prompt of another app, as a navigation app's turn, paused the reading (review 3, finding 7): it reads on
     * once the prompt gives the sound back. Android does not lower a voice for it, so it would talk over the module.
     */
    private var ducked = false

    /**
     * Another app took the sound for itself, as a call does: the reading pauses where it was. A short prompt pauses it
     * too, and the reading goes on when the prompt ends.
     */
    private val focus = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_LOSS, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                ducked = false
                main.post { interrupt() }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> if (current != null) {
                ducked = true
                main.post { interrupt() }
            }
            AudioManager.AUDIOFOCUS_GAIN -> if (ducked) {
                ducked = false
                main.post {
                    control("play")
                    // The focus goes back if the Dart side does not read on, as when the reader left the module.
                    releaseSoon()
                }
            }
        }
    }

    /**
     * Takes the sound while the voice speaks, so other sound pauses, as a podcast does and as on iOS (the owner,
     * 2026-11-19, plan 20.11): a module is minutes long, too long to read over music turned down.
     */
    private val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
        .setAudioAttributes(attributes)
        .setOnAudioFocusChangeListener(focus, main)
        .build()

    /** The reading as the phone shows it to the headphones and the lock screen (plan 19.8). */
    private val session = MediaSession(context, "Listen").apply {
        setCallback(
            object : MediaSession.Callback() {
                override fun onPlay() = control("play")

                override fun onPause() = control("pause")

                override fun onStop() = control("pause")
            },
            main,
        )
    }

    private fun control(command: String) {
        channel.invokeMethod("control", command)
    }

    /** Whether a reading is shown, playing or paused: its notice stays while it is (plan 19.8). */
    private var shown = false

    /**
     * Names the reading to the session and the notice: [title] and whether it is [playing], or nothing when [title] is
     * null, which ends the notice once nothing is said.
     */
    private fun show(title: String?, playing: Boolean) {
        shown = title != null
        if (title == null) {
            session.isActive = false
            ListenService.session = null
            if (current == null) ListenService.stop(context)
            return
        }
        session.setMetadata(MediaMetadata.Builder().putString(MediaMetadata.METADATA_KEY_TITLE, title).build())
        session.setPlaybackState(
            PlaybackState.Builder()
                .setActions(PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or PlaybackState.ACTION_PLAY_PAUSE)
                .setState(if (playing) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED, 0, 1f)
                .build(),
        )
        session.isActive = true
        ListenService.session = session.sessionToken
        ListenService.show(context, title, playing)
    }

    private val release = Runnable {
        // While a short prompt has the sound, the focus is kept, so its end comes back as a gain.
        if (current != null || ducked) return@Runnable
        audio?.abandonAudioFocusRequest(focusRequest)
        // A paused reading keeps its notice and its Play until it ends (plan 19.8).
        if (!shown) ListenService.stop(context)
    }

    private val progress = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {
            val part = parse(utteranceId) ?: return
            if (!part.starts) return
            main.post { channel.invokeMethod("part", mapOf("id" to part.id, "index" to part.index)) }
        }

        override fun onDone(utteranceId: String?) {
            val part = parse(utteranceId) ?: return
            if (part.last && part.ends) done(part.id)
        }

        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) = cut(utteranceId)

        override fun onError(utteranceId: String?, errorCode: Int) = cut(utteranceId)

        override fun onStop(utteranceId: String?, interrupted: Boolean) = cut(utteranceId)
    }

    /**
     * The headphones were taken off or lost, as Bluetooth ones whose battery ran out: the reading pauses rather than go
     * on aloud through the speaker (plan 20.3).
     */
    private val noisy = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != AudioManager.ACTION_AUDIO_BECOMING_NOISY) return
            main.post {
                // A reading paused by a short prompt stays paused too: its end must not read on through the speaker.
                ducked = false
                interrupt()
                releaseSoon()
            }
        }
    }

    init {
        ListenService.onPause = { main.post { interrupt() } }
        ListenService.onPlay = { main.post { control("play") } }
        val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(noisy, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                context.registerReceiver(noisy, filter)
            }
        }
    }

    private fun cut(utteranceId: String?) {
        val part = parse(utteranceId) ?: return
        done(part.id)
    }

    private fun done(id: Int) {
        main.post {
            if (!ended.add(id)) return@post
            channel.invokeMethod("done", id)
            if (current == id) {
                current = null
                // Other sound comes back up once nothing is said: a moment later, as a new speak follows at once.
                releaseSoon()
            }
        }
    }

    /** Gives the sound back a moment later, unless a reading or a short prompt's pause holds it by then. */
    private fun releaseSoon() {
        main.removeCallbacks(release)
        main.postDelayed(release, RELEASE_MS)
    }

    /** Stops the reading for the reader or another app, and tells the Dart side, which pauses where it was. */
    private fun interrupt() {
        val id = current ?: return
        channel.invokeMethod("interrupted", id)
        engine?.stop()
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
                engine?.setAudioAttributes(attributes)
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
                // The reader went on before the prompt ended: nothing is to come back.
                ducked = false
                val id = call.argument<Int>("id") ?: return result.error("no-id", null, null)
                val texts = call.argument<List<String>>("texts") ?: emptyList()
                val tag = call.argument<String>("tag") ?: return result.error("no-tag", null, null)
                val rate = call.argument<Double>("rate") ?: 1.0
                val title = call.argument<String>("title").orEmpty()
                // At once, while the reader still sees the app: Android refuses a foreground service started from the
                // background, as a reader who leaves while the engine starts would have it (plan 19.9).
                main.removeCallbacks(release)
                ListenService.start(context, title)
                whenStarted { tts ->
                    val locale = Locale.forLanguageTag(tag)
                    if (tts == null || texts.isEmpty() || !available(tts.setLanguage(locale))) {
                        // Not stopped at once: the service was started in this same step, and Android ends an app
                        // that stops one before it has started in the foreground (plan 20.1). The release stops it
                        // a moment later, unless a reading is still shown.
                        if (current == null) releaseSoon()
                        return@whenStarted result.success(false)
                    }
                    pickVoice(tts, locale)
                    tts.setSpeechRate(rate.toFloat())
                    main.removeCallbacks(release)
                    current = id
                    val focus = audio?.requestAudioFocus(focusRequest) ?: AudioManager.AUDIOFOCUS_REQUEST_GRANTED
                    if (focus != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                        // Another app holds the sound, as a call does: nothing is said, and the player waits on its
                        // part, as if the call had come during the reading (plan 19.10).
                        tts.stop()
                        main.post {
                            interrupt()
                            done(id)
                        }
                        return@whenStarted result.success(true)
                    }
                    // The first flushes the words being said, whose speak then comes back as done; the rest queue.
                    val max = runCatching { TextToSpeech.getMaxSpeechInputLength() }.getOrDefault(4000)
                    var queued = true
                    var flush = true
                    texts.forEachIndexed { index, text ->
                        val last = index == texts.size - 1
                        val pieces = pieces(text, max)
                        pieces.forEachIndexed { piece, words ->
                            val mode = if (flush) TextToSpeech.QUEUE_FLUSH else TextToSpeech.QUEUE_ADD
                            flush = false
                            val utterance = utterance(id, index, last, piece, pieces.size)
                            queued = queued && tts.speak(words, mode, null, utterance) == TextToSpeech.SUCCESS
                        }
                        if (!last) tts.playSilentUtterance(GAP_MS, TextToSpeech.QUEUE_ADD, "gap")
                    }
                    if (!queued) {
                        // Nothing half said: what was queued is cut, and the speak comes back as done.
                        tts.stop()
                        done(id)
                    }
                    result.success(queued)
                }
            }
            "stop" -> {
                engine?.stop()
                // Ended here as well, not only when the engine reports it: an engine that does not call back after a
                // stop would leave the service and its notice up (review 3, finding 6). A second end is ignored.
                current?.let { done(it) }
                result.success(null)
            }
            "show" -> {
                val reading = call.arguments as? Map<*, *>
                show(reading?.get("title") as? String, reading?.get("playing") as? Boolean ?: false)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Shuts the engine down with the activity. */
    fun close() {
        channel.setMethodCallHandler(null)
        runCatching { context.unregisterReceiver(noisy) }
        show(null, false)
        session.release()
        ListenService.onPause = null
        ListenService.onPlay = null
        main.removeCallbacks(release)
        current = null
        audio?.abandonAudioFocusRequest(focusRequest)
        ListenService.stop(context)
        engine?.shutdown()
        engine = null
        started = null
        waiting.clear()
    }
}
