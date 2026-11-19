package dev.lokumai.bazaar

import android.app.Activity
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
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
 */
class CodeScanner(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "dev.lokumai.bazaar/scanner"
    }

    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(
                    GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(activity) == ConnectionResult.SUCCESS,
                )
                "scan" -> scan(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun scan(result: MethodChannel.Result) {
        val options = GmsBarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build()
        GmsBarcodeScanning.getClient(activity, options).startScan()
            .addOnSuccessListener { code -> result.success(code.rawValue) }
            .addOnCanceledListener { result.success(null) }
            .addOnFailureListener { error -> result.error("no-scanner", error.message, null) }
    }

    fun close() {
        channel.setMethodCallHandler(null)
    }
}
