package com.example.carecircle_parent1

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * 🎧 ParentAudioService — Foreground Service for Parent Live Audio Listening
 *
 * Keeps audio stream alive in background when parent switches apps or locks phone.
 * Shows persistent notification with a STOP button (like a music player app).
 * When user clicks STOP in notification tray -> sends ACTION_USER_NOTIFICATION_STOP -> notifies Flutter.
 * When Flutter programmatically calls stopService -> sends ACTION_STOP -> dismisses without looping.
 */
class ParentAudioService : Service() {

    companion object {
        private const val TAG = "ParentAudioService"
        private const val NOTIFICATION_ID = 9001
        private const val CHANNEL_ID = "carecircle_parent_audio_channel"
        private const val CHANNEL_NAME = "Live Audio Surroundings"

        const val ACTION_START = "com.example.carecircle_parent1.ACTION_START_AUDIO"
        const val ACTION_STOP = "com.example.carecircle_parent1.ACTION_STOP_AUDIO"
        const val ACTION_USER_NOTIFICATION_STOP = "com.example.carecircle_parent1.ACTION_USER_NOTIFICATION_STOP"
        const val EXTRA_CHILD_UID = "extra_child_uid"
        const val EXTRA_CHILD_NAME = "extra_child_name"

        var isRunning = false
            private set

        var activeChildUid: String? = null
            private set

        var activeChildName: String? = null
            private set

        fun startService(context: Context, childUid: String, childName: String) {
            val intent = Intent(context, ParentAudioService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_CHILD_UID, childUid)
                putExtra(EXTRA_CHILD_NAME, childName)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, ParentAudioService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        // 1. User clicked "Stop Listening" button ON the notification itself
        if (action == ACTION_USER_NOTIFICATION_STOP) {
            Log.d(TAG, "⏹ User tapped Stop button in notification bar — notifying Flutter")
            try {
                MainActivity.audioMethodChannel?.invokeMethod("onNotificationStopPressed", null)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to notify Flutter of notification stop: ${e.message}")
            }
            dismissNotificationAndStop()
            return START_NOT_STICKY
        }

        // 2. Flutter programmatically requested to stop/dismiss notification (DO NOT echo back to Flutter!)
        if (action == ACTION_STOP) {
            Log.d(TAG, "⏹ Dismiss requested by Flutter app — cleaning up notification")
            dismissNotificationAndStop()
            return START_NOT_STICKY
        }

        // 3. Start foreground notification
        val childUid = intent?.getStringExtra(EXTRA_CHILD_UID)
        val childName = intent?.getStringExtra(EXTRA_CHILD_NAME) ?: "Child"

        if (!childUid.isNullOrEmpty()) {
            activeChildUid = childUid
            activeChildName = childName
        }

        val displayName = activeChildName ?: "Child"
        val notification = buildListeningNotification(displayName)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            isRunning = true
            Log.d(TAG, "✅ Parent audio foreground service started for $displayName")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to startForeground: ${e.message}")
        }

        return START_NOT_STICKY
    }

    private fun dismissNotificationAndStop() {
        activeChildUid = null
        activeChildName = null
        isRunning = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    /**
     * When user clears RAM / swipes app away from Recent Apps,
     * clean up the foreground notification.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.w(TAG, "🚨 Parent app swiped from recents (RAM cleared)! Cleaning up notification")
        dismissNotificationAndStop()
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }

    private fun buildListeningNotification(childName: String): android.app.Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // When user taps "Stop Listening" on notification tray -> send ACTION_USER_NOTIFICATION_STOP
        val stopIntent = Intent(this, ParentAudioService::class.java).apply {
            action = ACTION_USER_NOTIFICATION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Listening to $childName")
            .setContentText("Live surroundings audio is streaming")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(contentPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop Listening",
                stopPendingIntent
            )
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows live audio streaming status with stop action"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
