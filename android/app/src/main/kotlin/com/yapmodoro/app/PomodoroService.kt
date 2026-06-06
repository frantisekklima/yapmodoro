package com.yapmodoro.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import android.content.pm.ServiceInfo

class PomodoroService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var completionRunnable: Runnable? = null
    
    companion object {
        private const val TAG = "PomodoroService"
        const val CHANNEL_ID_TIMER = "pomodoro_timer"
        const val CHANNEL_ID_ALARM = "pomodoro_alarm_v3"
        const val NOTIFICATION_ID = 888
        const val ALARM_NOTIFICATION_ID = 999
        
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_END_TIME = "endTimeMillis"
        const val EXTRA_IS_COUNTDOWN = "isCountdown"
        const val EXTRA_ALARM_TITLE = "alarmTitle"
        const val EXTRA_ALARM_BODY = "alarmBody"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Pomodoro Active"
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val endTimeMillis = intent.getLongExtra(EXTRA_END_TIME, 0L)
        val isCountdown = intent.getBooleanExtra(EXTRA_IS_COUNTDOWN, true)
        val alarmTitle = intent.getStringExtra(EXTRA_ALARM_TITLE) ?: "Session Completed!"
        val alarmBody = intent.getStringExtra(EXTRA_ALARM_BODY) ?: "Time's up!"

        Log.d(TAG, "Starting PomodoroService: title=$title, endTime=$endTimeMillis")

        // 1. Create notification channels if they do not exist
        createNotificationChannels()

        // 2. Build the ongoing foreground notification
        val notification = buildOngoingNotification(title, body, endTimeMillis, isCountdown)

        // 3. Start foreground service
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
                } else {
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service: ${e.message}", e)
            // Fallback without foreground service type if it fails
            startForeground(NOTIFICATION_ID, notification)
        }

        // 4. Schedule native completion logic (both in-app Handler and system AlarmManager)
        if (isCountdown) {
            scheduleCompletion(endTimeMillis, alarmTitle, alarmBody)
        }

        return START_REDELIVER_INTENT
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Timer channel (Low importance, silent)
            if (notificationManager.getNotificationChannel(CHANNEL_ID_TIMER) == null) {
                val timerChannel = NotificationChannel(
                    CHANNEL_ID_TIMER,
                    "Pomodoro Active Timer",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Displays a live, silent countdown timer in the status drawer."
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                }
                notificationManager.createNotificationChannel(timerChannel)
            }

            // Alarm channel (High importance, system sound, vibration)
            if (notificationManager.getNotificationChannel(CHANNEL_ID_ALARM) == null) {
                val alarmChannel = NotificationChannel(
                    CHANNEL_ID_ALARM,
                    "Pomodoro Session Alarm",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Rings and alerts when focus or break sessions complete."
                    enableLights(true)
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(alarmChannel)
            }
        }
    }

    private fun buildOngoingNotification(
        title: String,
        body: String,
        endTimeMillis: Long,
        isCountdown: Boolean
    ): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconId = resources.getIdentifier("ic_launcher", "mipmap", packageName)

        return NotificationCompat.Builder(this, CHANNEL_ID_TIMER)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(if (iconId != 0) iconId else android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(endTimeMillis > 0)
            .setUsesChronometer(endTimeMillis > 0)
            .setChronometerCountDown(isCountdown)
            .setWhen(endTimeMillis)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun scheduleCompletion(endTimeMillis: Long, alarmTitle: String, alarmBody: String) {
        // Cancel existing handler runnables
        completionRunnable?.let { handler.removeCallbacks(it) }

        val delay = endTimeMillis - System.currentTimeMillis()
        Log.d(TAG, "Scheduling completion in $delay ms")

        if (delay <= 0) {
            triggerCompletion(alarmTitle, alarmBody)
            return
        }

        val runnable = Runnable {
            Log.d(TAG, "Completion handler fired")
            triggerCompletion(alarmTitle, alarmBody)
        }
        completionRunnable = runnable
        handler.postDelayed(runnable, delay)

        // Schedule exact AlarmManager alarm as a backup for Doze mode survival
        scheduleAlarmManager(endTimeMillis, alarmTitle, alarmBody)
    }

    private fun scheduleAlarmManager(endTimeMillis: Long, alarmTitle: String, alarmBody: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, PomodoroAlarmReceiver::class.java).apply {
            putExtra(EXTRA_ALARM_TITLE, alarmTitle)
            putExtra(EXTRA_ALARM_BODY, alarmBody)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        Log.d(TAG, "Scheduling AlarmManager exact alarm at $endTimeMillis")
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    endTimeMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    endTimeMillis,
                    pendingIntent
                )
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException: Exact alarm permission not granted: ${e.message}")
            // Fallback to non-exact alarm if exact is not permitted
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                endTimeMillis,
                pendingIntent
            )
        }
    }

    private fun triggerCompletion(alarmTitle: String, alarmBody: String) {
        Log.d(TAG, "triggerCompletion called")
        // Show session completion notification
        showCompletionNotification(alarmTitle, alarmBody)
        
        // Stop foreground notification and service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun showCompletionNotification(title: String, body: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconId = resources.getIdentifier("ic_launcher", "mipmap", packageName)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID_ALARM)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(if (iconId != 0) iconId else android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setDefaults(Notification.DEFAULT_ALL)
            .build()

        notificationManager.notify(ALARM_NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called")
        completionRunnable?.let { handler.removeCallbacks(it) }
        super.onDestroy()
    }
}
