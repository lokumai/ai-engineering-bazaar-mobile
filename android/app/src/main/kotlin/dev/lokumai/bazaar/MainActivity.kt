package dev.lokumai.bazaar

import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.sentry.Sentry

class MainActivity : FlutterActivity() {
    /** The app icon chosen on the Dart side and not yet put in the launcher (AppIconSwitch). */
    private var chosenIcon: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Until Flutter's first frame the window shows; it takes the ground of the reader's look, where the opening starts.
        window.setBackgroundDrawable(ColorDrawable(getColor(LaunchGround.ground(this))))
    }

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

    override fun onStop() {
        super.onStop()
        chosenIcon?.let {
            AppIconSwitch.apply(this, it)
            chosenIcon = null
        }
    }
}
