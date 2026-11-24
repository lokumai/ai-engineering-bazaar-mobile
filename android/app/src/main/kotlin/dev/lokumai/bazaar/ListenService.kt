package dev.lokumai.bazaar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.media.session.MediaSession
import android.os.Build
import android.os.IBinder
import java.util.Locale

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

        /** The service running, to leave the foreground while the reading is paused. */
        private var instance: ListenService? = null

        /** The starts asked for and the stops waiting on them (plan 20.1). */
        private val starts = ListenStarts()

        /** Told when the reader presses Pause on the notice. */
        var onPause: (() -> Unit)? = null

        /** Told when the reader presses Play on the notice of a paused reading (plan 19.8). */
        var onPlay: (() -> Unit)? = null

        /**
         * The app's own language (en, tr, fa), which the notice's words are in; null keeps the phone's. The app's
         * language is its own choice, so a phone in English with the app in Turkish said "Reading aloud" and "Pause"
         * beside a Turkish title (review 2 finding 13, review 5 finding 8).
         */
        var language: String? = null

        /** The reading's MediaSession, which the notice names so the lock screen shows its controls (plan 19.8). */
        var session: MediaSession.Token? = null

        /** Starts the service, or names [title] to the one running. Fails quietly where Android refuses a start. */
        fun start(context: Context, title: String) {
            val intent = Intent(context, ListenService::class.java).putExtra(EXTRA_TITLE, title)
            starts.asked()
            runCatching { context.startForegroundService(intent) }.onFailure { starts.refused() }
        }

        /**
         * Names [title], playing or paused, on the notice of the service running (plan 19.8): a paused reading keeps
         * its notice, with Play, until it ends.
         */
        fun show(context: Context, title: String, playing: Boolean) {
            if (!running) return
            val service = context.applicationContext
            // Paused, nothing is played: the service leaves the foreground and keeps its notice, which the reader may
            // then swipe away; the next speak brings it back to the foreground (review 11, native 4).
            if (!playing) runCatching { instance?.stopForeground(STOP_FOREGROUND_DETACH) }
            runCatching {
                service.getSystemService(NotificationManager::class.java)
                    .notify(NOTICE_ID, notice(service, title, playing))
            }
        }

        /**
         * Stops the service; one asked to start that has not yet come to the foreground stops once it has, since
         * Android ends an app that stops such a service before (plan 20.1).
         */
        fun stop(context: Context) {
            if (!starts.stop()) return
            runCatching { context.stopService(Intent(context, ListenService::class.java)) }
            // A paused reading's notice is no longer the service's, so it does not go with it.
            clearNotice(context)
        }

        /** Takes down a paused reading's notice left from an app ended before, when no service runs. */
        fun clearStale(context: Context) {
            if (!running) clearNotice(context)
        }

        /**
         * Takes down the notice: a paused reading's stays after its service has gone, as after the app was ended in the
         * background, with a Play that has no reading behind it.
         */
        fun clearNotice(context: Context) {
            runCatching { context.getSystemService(NotificationManager::class.java).cancel(NOTICE_ID) }
        }

        /** [context]'s resources in [language], for the notice's words. */
        private fun words(context: Context): Context {
            val tag = language ?: return context
            return runCatching {
                val config = Configuration(context.resources.configuration).apply { setLocale(Locale.forLanguageTag(tag)) }
                context.createConfigurationContext(config)
            }.getOrDefault(context)
        }

        private fun notice(context: Context, title: String, playing: Boolean): Notification {
            val words = words(context)
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    words.getString(R.string.listen_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    setShowBadge(false)
                    setSound(null, null)
                },
            )
            // The activity itself, not the launcher's entry: the entry of the icon chosen before may be turned off
            // since (plan 20.10).
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
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
                .setContentTitle(title.ifEmpty { words.getString(R.string.listen_reading) })
                .setContentText(words.getString(if (playing) R.string.listen_reading else R.string.listen_paused))
                .setContentIntent(open)
                // A paused reading's notice is no longer a foreground service's, and may be swiped away.
                .setOngoing(playing)
                .setOnlyAlertOnce(true)
                .setCategory(Notification.CATEGORY_TRANSPORT)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .addAction(
                    Notification.Action.Builder(Icon.createWithResource(context, icon), words.getString(label), press)
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
            val play = onPlay
            if (play == null) {
                // The app was ended since the reading was paused: no reading to play, so its notice goes.
                clearNotice(this)
                if (!running) stopSelf(startId)
            } else {
                play()
            }
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE).orEmpty()
        val notice = notice(this, title, intent?.getBooleanExtra(EXTRA_PLAYING, true) ?: true)
        // Android may refuse the foreground (a start it counts as from the background, a type it does not allow): the
        // reading then goes on with the app in front, without a notice, rather than the app ending (review 6, finding
        // 12).
        val foreground = runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTICE_ID, notice, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTICE_ID, notice)
            }
        }
        if (foreground.isSuccess) {
            running = true
            instance = this
        }
        if (starts.taken(foreground = foreground.isSuccess)) stopSelf()
        // A service Android stopped is not started again: the voice it kept going has stopped with it.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        if (instance === this) instance = null
        super.onDestroy()
    }

    /** The reader swiped the app away: the reading ends with it, as on iOS. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        onPause?.invoke()
        stopSelf()
    }
}
