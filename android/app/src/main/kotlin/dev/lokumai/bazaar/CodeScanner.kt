package dev.lokumai.bazaar

import android.app.Activity
import android.os.Handler
import android.os.Looper
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.moduleinstall.InstallStatusListener
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.android.gms.common.moduleinstall.ModuleInstallStatusUpdate
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The phone's QR code scanner (plan 17.5), on the channel lib/infrastructure/scanner/code_scanner_channel.dart calls:
 * `available`, and `scan`, which answers the code's text, or null when the reader went back. It is Google's code
 * scanner: Google Play services shows its own camera screen, so the app needs no camera permission and sees no picture,
 * only the code's text. A phone without Google Play services is not available; the reader then scans with its camera
 * app. The title the Dart side sends is iOS's; Google's screen has its own.
 *
 * Play services downloads the scanner's screen as a module the first time an app asks for it, so a scan asks for the
 * module first and waits for it (a phone where another app used the scanner has it already). A download that has not
 * ended in [INSTALL_LIMIT_MS] ends the scan as failed, so the Settings button comes back with its line on a slow or
 * missing connection (review 3, finding 8).
 */
class CodeScanner(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/scanner"
        const val INSTALL_LIMIT_MS = 60_000L
    }

    private val main = Handler(Looper.getMainLooper())

    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(
                    GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(activity) == ConnectionResult.SUCCESS,
                )
                "scan" -> scan(Once(result))
                else -> result.notImplemented()
            }
        }
    }

    private val scanner = GmsBarcodeScanning.getClient(
        activity,
        GmsBarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build(),
    )

    private val installer = ModuleInstall.getClient(activity)

    private fun scan(result: Once) {
        installer.areModulesAvailable(scanner)
            .addOnSuccessListener { answer ->
                if (answer.areModulesAvailable()) start(result) else install(result)
            }
            .addOnFailureListener { error -> result.error("no-scanner", error.message, null) }
    }

    /** Asks Play services for the scanner's module and starts the scan once it is in place, or gives up at the limit. */
    private fun install(result: Once) {
        lateinit var limit: Runnable
        val listener = object : InstallStatusListener {
            override fun onInstallStatusUpdated(update: ModuleInstallStatusUpdate) {
                when (update.installState) {
                    ModuleInstallStatusUpdate.InstallState.STATE_COMPLETED -> {
                        done(this, limit)
                        if (!result.answered) start(result)
                    }
                    ModuleInstallStatusUpdate.InstallState.STATE_FAILED,
                    ModuleInstallStatusUpdate.InstallState.STATE_CANCELED -> {
                        done(this, limit)
                        result.error("no-scanner", "module ${update.installState}", null)
                    }
                    else -> Unit
                }
            }
        }
        limit = Runnable {
            installer.unregisterListener(listener)
            result.error("no-scanner", "module not in place after ${INSTALL_LIMIT_MS / 1000} s", null)
        }
        main.postDelayed(limit, INSTALL_LIMIT_MS)
        val request = ModuleInstallRequest.newBuilder().addApi(scanner).setListener(listener).build()
        installer.installModules(request)
            .addOnSuccessListener { answer ->
                if (answer.areModulesAlreadyInstalled()) {
                    done(listener, limit)
                    if (!result.answered) start(result)
                }
            }
            .addOnFailureListener { error ->
                done(listener, limit)
                result.error("no-scanner", error.message, null)
            }
    }

    private fun done(listener: InstallStatusListener, limit: Runnable) {
        installer.unregisterListener(listener)
        main.removeCallbacks(limit)
    }

    private fun start(result: Once) {
        scanner.startScan()
            .addOnSuccessListener { code -> result.success(code.rawValue) }
            .addOnCanceledListener { result.success(null) }
            .addOnFailureListener { error -> result.error("no-scanner", error.message, null) }
    }

    fun close() {
        main.removeCallbacksAndMessages(null)
        channel.setMethodCallHandler(null)
    }

    /** A channel's result answered at most once: the limit and a late answer from Play services may both come. */
    class Once(private val result: MethodChannel.Result) {
        var answered = false
            private set

        fun success(value: Any?) {
            if (answered) return
            answered = true
            result.success(value)
        }

        fun error(code: String, message: String?, details: Any?) {
            if (answered) return
            answered = true
            result.error(code, message, details)
        }
    }
}
