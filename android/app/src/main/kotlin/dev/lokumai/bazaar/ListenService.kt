package dev.lokumai.bazaar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder

/**
 * Keeps the app running while the phone's voice reads a module aloud, so the reading goes on with the screen off and
 * the app in the background, as iOS's audio background mode does (plan 18.1). Speech.kt starts it with the first part
 * of a speak and stops it a moment after the last.
 *
 * Android shows a foreground service as a notice: the module's title, the words "Reading aloud" and a Pause, which the
 * reader may hide; Android 13 and later hide it unless the app may post notifications, which it never asks for, and the
 * reading goes on all the same. Pause comes back to Speech.kt as an interruption, which the Dart side reads as the
 * player's own pause, so the place is kept.
 */
class ListenService : Service() {
    companion object {
        private const val CHANNEL_ID = "listen"
        private const val NOTICE_ID = 15
        private const val EXTRA_TITLE = "title"
        private const val ACTION_PAUSE = "dev.lokumai.bazaar.listen.PAUSE"

        /** Told when the reader presses Pause on the notice. */
        var onPause: (() -> Unit)? = null

        /** Starts the service, or names [title] to the one running. Fails quietly where Android refuses a start. */
        fun start(context: Context, title: String) {
            val intent = Intent(context, ListenService::class.java).putExtra(EXTRA_TITLE, title)
            runCatching { context.startForegroundService(intent) }
        }

        fun stop(context: Context) {
            runCatching { context.stopService(Intent(context, ListenService::class.java)) }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_PAUSE) {
            onPause?.invoke()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE).orEmpty()
        val notice = notice(title)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTICE_ID, notice, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTICE_ID, notice)
        }
        // A service Android stopped is not started again: the voice it kept going has stopped with it.
        return START_NOT_STICKY
    }

    /** The reader swiped the app away: the reading ends with it, as on iOS. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        onPause?.invoke()
        stopSelf()
    }

    private fun notice(title: String): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, getString(R.string.listen_channel), NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
                setSound(null, null)
            },
        )
        val open = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val pause = PendingIntent.getService(
            this,
            1,
            Intent(this, ListenService::class.java).setAction(ACTION_PAUSE),
            PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_listen)
            .setContentTitle(title.ifEmpty { getString(R.string.listen_reading) })
            .setContentText(getString(R.string.listen_reading))
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_TRANSPORT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, R.drawable.ic_listen_pause),
                    getString(R.string.listen_pause),
                    pause,
                ).build(),
            )
            .setStyle(Notification.MediaStyle().setShowActionsInCompactView(0))
            .build()
    }
}
