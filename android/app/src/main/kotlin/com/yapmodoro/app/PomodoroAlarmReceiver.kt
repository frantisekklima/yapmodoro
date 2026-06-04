package com.yapmodoro.app

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class PomodoroAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PomodoroAlarmReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val alarmTitle = intent.getStringExtra(PomodoroService.EXTRA_ALARM_TITLE) ?: "Session Completed!"
        val alarmBody = intent.getStringExtra(PomodoroService.EXTRA_ALARM_BODY) ?: "Time's up!"

        Log.d(TAG, "Alarm received! Title: $alarmTitle, Body: $alarmBody")

        // 1. Stop the running PomodoroService (this removes ongoing notification 888)
        val serviceIntent = Intent(context, PomodoroService::class.java)
        context.stopService(serviceIntent)

        // 2. Show completion notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconId = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)

        val notification = NotificationCompat.Builder(context, PomodoroService.CHANNEL_ID_ALARM)
            .setContentTitle(alarmTitle)
            .setContentText(alarmBody)
            .setSmallIcon(if (iconId != 0) iconId else android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setDefaults(Notification.DEFAULT_ALL)
            .build()

        notificationManager.notify(PomodoroService.ALARM_NOTIFICATION_ID, notification)
    }
}
