package dev.lokumai.bazaar

import android.content.Context
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The robot's touch feedback on Android (plan 18.12), on the channel lib/infrastructure/haptics/haptics_channel.dart
 * calls with one of `selection`, `light`, `medium` and `heavy`. Flutter's own HapticFeedback maps these to old
 * keyboard and clock ticks that many phones play as a buzz. Here each is one of the haptic primitives, the short crisp
 * taps a phone composes only where its motor can (Android 11 and later), scaled as soft as iOS's. A phone that cannot
 * compose them plays nothing: a tap like the iPhone's or none, never a buzz (the owner, 2026-11-19). Like a key's
 * feedback they follow the reader's touch feedback setting.
 */
class Haptics(context: Context, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/haptics"

        /** The kinds the Dart side names. */
        val kinds = setOf("selection", "light", "medium", "heavy")

        /** Each kind as one primitive and its scale, 0 to 1, where the phone composes primitives (Android 11+). */
        fun primitive(kind: String): Pair<Int, Float>? = when (kind) {
            "selection" -> VibrationEffect.Composition.PRIMITIVE_TICK to 0.4f
            "light" -> VibrationEffect.Composition.PRIMITIVE_CLICK to 0.3f
            "medium" -> VibrationEffect.Composition.PRIMITIVE_CLICK to 0.5f
            "heavy" -> VibrationEffect.Composition.PRIMITIVE_CLICK to 0.7f
            else -> null
        }
    }

    private val vibrator: Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Vibrator::class.java)
        }

    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val kind = call.arguments as? String
                    if (kind == null || kind !in kinds) return@setMethodCallHandler result.error("unknown-kind", kind, null)
                    runCatching { play(kind) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun play(kind: String) {
        val vibrator = vibrator?.takeIf { it.hasVibrator() } ?: return
        val effect = effect(vibrator, kind) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(effect)
        }
    }

    /** The kind as a composed primitive, or null where the phone cannot play it as a crisp tap. */
    private fun effect(vibrator: Vibrator, kind: String): VibrationEffect? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val (primitive, scale) = primitive(kind) ?: return null
        if (!vibrator.areAllPrimitivesSupported(primitive)) return null
        return VibrationEffect.startComposition().addPrimitive(primitive, scale).compose()
    }

    fun close() {
        channel.setMethodCallHandler(null)
    }
}
