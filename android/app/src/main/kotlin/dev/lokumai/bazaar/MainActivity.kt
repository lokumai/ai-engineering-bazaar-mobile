package dev.lokumai.bazaar

import android.content.Intent
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.sentry.Sentry

class MainActivity : FlutterActivity() {
    /** The app icon chosen on the Dart side and not yet put in the launcher (AppIconSwitch). */
    private var chosenIcon: String? = null

    /** The phone's voice, which reads a module aloud (plan 15.1). */
    private var speech: Speech? = null

    /** The links the phone hands the app (plan 17.2). */
    private var links: Links? = null

    /** The phone's share sheet (plan 17.3). */
    private var shareSheet: ShareSheet? = null

    /** The phone's QR code scanner (plan 17.5). */
    private var codeScanner: CodeScanner? = null

    /** The robot's touch feedback (plan 18.12). */
    private var haptics: Haptics? = null

    /** Whether this activity is made again from a saved state, whose intent's link was handed over already. */
    private var restored = false

    override fun onCreate(savedInstanceState: Bundle?) {
        restored = savedInstanceState != null
        super.onCreate(savedInstanceState)
        // Until Flutter's first frame the window shows; it takes the ground of the reader's look, where the opening starts.
        window.setBackgroundDrawable(ColorDrawable(getColor(LaunchGround.ground(this))))
    }

    /**
     * The engine is always the activity's own. The activity is exported, and FlutterActivity reads a cached engine's id,
     * or its group's, from the intent: another app naming one that does not exist ended that launch (review 10,
     * finding 9).
     */
    override fun getCachedEngineId(): String? = null

    override fun getCachedEngineGroupId(): String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // nativeSdkReady (lib/infrastructure/analytics/native_sentry_start.dart) asks whether MainApplication started
        // the native Sentry SDK before the Dart side starts its own.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.lokumai.bazaar/native_sentry")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEnabled" -> result.success(Sentry.isEnabled())
                    else -> result.notImplemented()
                }
            }
        // lib/infrastructure/app_icon/app_icon_channel.dart names the icon the reader chose; it reaches the launcher
        // when the app goes to the background.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AppIconSwitch.CHANNEL)
            .setMethodCallHandler { call, result ->
                val icon = call.arguments as? String
                when {
                    call.method != "choose" -> result.notImplemented()
                    icon == null || icon !in AppIconSwitch.aliases -> result.error("unknown-icon", icon, null)
                    else -> {
                        chosenIcon = icon
                        result.success(null)
                    }
                }
            }
        handleLaunchGround(flutterEngine)
        // lib/infrastructure/speech/phone_speech.dart reads a module aloud with the phone's own voice.
        speech = Speech(this, flutterEngine.dartExecutor.binaryMessenger).also {
            // An icon chosen while a module was read aloud reaches the launcher once the reading ends in the background.
            it.onReadingEnded = { if (stopped) applyChosenIcon() }
        }
        // lib/infrastructure/links/link_channel.dart opens the site's links in the app; the one the app was opened
        // with waits for it.
        links = Links(this, flutterEngine.dartExecutor.binaryMessenger).also { if (!restored) it.receive(intent) }
        // lib/infrastructure/share/share_channel.dart shares a module's address and a progress link.
        shareSheet = ShareSheet(this, flutterEngine.dartExecutor.binaryMessenger)
        // lib/infrastructure/scanner/code_scanner_channel.dart reads the website's code in the app.
        codeScanner = CodeScanner(this, flutterEngine.dartExecutor.binaryMessenger)
        // lib/infrastructure/haptics/haptics_channel.dart plays the robot's touch feedback.
        haptics = Haptics(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    /**
     * Back on Home, where the app has no page to go back to, puts the app in the background instead of closing it, as
     * Android's own launcher apps do since Android 12 (plan 18.2): a module read aloud goes on, and the next open comes
     * back where the reader was, without the opening.
     */
    override fun popSystemNavigator(): Boolean {
        moveTaskToBack(true)
        return true
    }

    /**
     * Back always goes through Flutter, so it reaches [popSystemNavigator] on Home too. With predictive back (Android 13
     * and later opted in, every app from Android 16) Flutter hands Back at its root to the system, which finished the
     * activity (seen on Android 16, 2026-11-19). The cost: no preview of the launcher behind Home while the gesture is
     * held; the app's own pages keep theirs.
     */
    override fun setFrameworkHandlesBack(frameworkHandlesBack: Boolean) {
        super.setFrameworkHandlesBack(true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        links?.receive(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        speech?.onReadingEnded = null
        speech?.close()
        speech = null
        // An icon still waiting on a reading reaches the launcher as the activity goes.
        applyChosenIcon()
        links?.close()
        links = null
        shareSheet?.close()
        shareSheet = null
        codeScanner?.close()
        codeScanner = null
        haptics?.close()
        haptics = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun handleLaunchGround(flutterEngine: FlutterEngine) {
        // lib/infrastructure/theme/launch_ground_channel.dart names the reader's look on every launch and every choice.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LaunchGround.CHANNEL)
            .setMethodCallHandler { call, result ->
                val look = call.arguments as? String
                when {
                    call.method != "keep" -> result.notImplemented()
                    look == null || look !in LaunchGround.grounds -> result.error("unknown-look", look, null)
                    else -> {
                        LaunchGround.apply(this, look)
                        result.success(null)
                    }
                }
            }
    }

    /** Whether the activity is in the background, where a chosen icon may reach the launcher. */
    private var stopped = false

    override fun onStart() {
        super.onStart()
        stopped = false
    }

    override fun onStop() {
        super.onStop()
        stopped = true
        applyChosenIcon()
    }

    /**
     * Sends the icon the reader chose to the launcher, unless a module is being read aloud: turning off the launcher entry
     * the app was opened through can finish its activity even with DONT_KILL_APP, and the reading with it (review 11,
     * native 1). It then waits for the reading to end in the background, or for the next time the app goes there.
     */
    private fun applyChosenIcon() {
        val icon = chosenIcon ?: return
        if (speech?.readingShown == true) return
        AppIconSwitch.apply(this, icon)
        chosenIcon = null
    }
}
