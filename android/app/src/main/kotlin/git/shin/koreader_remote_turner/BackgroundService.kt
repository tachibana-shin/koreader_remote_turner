package git.shin.koreader_remote_turner

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.session.MediaSession
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class BackgroundService : Service() {
    companion object {
        const val CHANNEL_ID = "koreader_remote_service"
        const val NOTIFICATION_ID = 1
        var mediaSession: MediaSession? = null
        var methodChannel: MethodChannel? = null
        var eventSink: EventChannel.EventSink? = null
            set(value) {
                field = value
                if (value != null) {
                    flushEventQueue()
                }
            }
        private val eventQueue = mutableListOf<String>()

        fun sendEvent(event: String) {
            if (eventSink != null) {
                eventSink?.success(event)
            } else {
                synchronized(eventQueue) {
                    eventQueue.add(event)
                }
            }
            methodChannel?.invokeMethod("volumeKeyPressed", event)
        }

        private fun flushEventQueue() {
            synchronized(eventQueue) {
                for (event in eventQueue) {
                    eventSink?.success(event)
                }
                eventQueue.clear()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        setupMediaSession()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
        eventSink = null
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "KOReader Remote Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Service for remote control"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("KOReader Remote")
            .setContentText("Server is running")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun setupMediaSession() {
        mediaSession = MediaSession(this, "KOReaderRemote")
        mediaSession?.setFlags(
            MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or
            MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS
        )
        mediaSession?.isActive = true
    }
}
