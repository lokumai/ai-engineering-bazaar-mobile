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
import android.media.session.MediaSession
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
 * player's own pause, so the place is kept. The notice names the reading's MediaSession, so the lock screen shows it
 * with its controls; a paused reading keeps its notice, which says Paused and has Play, until the reading ends
 * (plan 19.8).
 */
class ListenService : Service() {
    companion object {
        private const val CHANNEL_ID = "listen"
        private const val NOTICE_ID = 15
        private const val EXTRA_TITLE = "title"
        private const val ACTION_PAUSE = "dev.lokumai.bazaar.listen.PAUSE"
        private const val ACTION_PLAY = "dev.lokumai.bazaar.listen.PLAY"
        private const val EXTRA_PLAYING = "playing"

        /** Whether the service runs, so a paused reading's notice is changed in place, never started again. */
        private var running = false

        /** Told when the reader presses Pause on the notice. */
        var onPause: (() -> Unit)? = null

        /** Told when the reader presses Play on the notice of a paused reading (plan 19.8). */
        var onPlay: (() -> Unit)? = null

        /** The reading's MediaSession, which the notice names so the lock screen shows its controls (plan 19.8). */
        var session: MediaSession.Token? = null

        /** Starts the service, or names [title] to the one running. Fails quietly where Android refuses a start. */
        fun start(context: Context, title: String) {
            val intent = Intent(context, ListenService::class.java).putExtra(EXTRA_TITLE, title)
            runCatching { context.startForegroundService(intent) }
        }

        /**
         * Names [title], playing or paused, on the notice of the service running (plan 19.8): a paused reading keeps
         * its notice, with Play, until it ends.
         */
        fun show(context: Context, title: String, playing: Boolean) {
            if (!running) return
            val service = context.applicationContext
            runCatching {
                service.getSystemService(NotificationManager::class.java)
                    .notify(NOTICE_ID, notice(service, title, playing))
            }
        }

        fun stop(context: Context) {
            runCatching { context.stopService(Intent(context, ListenService::class.java)) }
        }

        private fun notice(context: Context, title: String, playing: Boolean): Notification {
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.listen_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    setShowBadge(false)
                    setSound(null, null)
                },
            )
            val open = PendingIntent.getActivity(
                context,
                0,
                context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val (action, icon, label) = if (playing) {
                Triple(ACTION_PAUSE, R.drawable.ic_listen_pause, R.string.listen_pause)
            } else {
                Triple(ACTION_PLAY, R.drawable.ic_listen_play, R.string.listen_play)
            }
            val press = PendingIntent.getService(
                context,
                if (playing) 1 else 2,
                Intent(context, ListenService::class.java).setAction(action),
                PendingIntent.FLAG_IMMUTABLE,
            )
            return Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_listen)
                .setContentTitle(title.ifEmpty { context.getString(R.string.listen_reading) })
                .setContentText(context.getString(if (playing) R.string.listen_reading else R.string.listen_paused))
                .setContentIntent(open)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setCategory(Notification.CATEGORY_TRANSPORT)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .addAction(
                    Notification.Action.Builder(Icon.createWithResource(context, icon), context.getString(label), press)
                        .build(),
                )
                .setStyle(
                    Notification.MediaStyle().setShowActionsInCompactView(0).also { style ->
                        session?.let { style.setMediaSession(it) }
                    },
                )
                .build()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_PAUSE) {
            onPause?.invoke()
            return START_NOT_STICKY
        }
        if (intent?.action == ACTION_PLAY) {
            onPlay?.invoke()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE).orEmpty()
        val notice = notice(this, title, intent?.getBooleanExtra(EXTRA_PLAYING, true) ?: true)
        running = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTICE_ID, notice, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTICE_ID, notice)
        }
        // A service Android stopped is not started again: the voice it kept going has stopped with it.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        super.onDestroy()
    }

    /** The reader swiped the app away: the reading ends with it, as on iOS. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        onPause?.invoke()
        stopSelf()
    }
}
