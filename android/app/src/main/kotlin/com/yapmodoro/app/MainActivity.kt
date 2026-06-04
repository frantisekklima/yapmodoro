package com.yapmodoro.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yapmodoro.app/timer_service"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val endTimeMillis = call.argument<Long>("endTimeMillis") ?: 0L
                    val isCountdown = call.argument<Boolean>("isCountdown") ?: true
                    val alarmTitle = call.argument<String>("alarmTitle")
                    val alarmBody = call.argument<String>("alarmBody")

                    val intent = Intent(this, PomodoroService::class.java).apply {
                        putExtra(PomodoroService.EXTRA_TITLE, title)
                        putExtra(PomodoroService.EXTRA_BODY, body)
                        putExtra(PomodoroService.EXTRA_END_TIME, endTimeMillis)
                        putExtra(PomodoroService.EXTRA_IS_COUNTDOWN, isCountdown)
                        putExtra(PomodoroService.EXTRA_ALARM_TITLE, alarmTitle)
                        putExtra(PomodoroService.EXTRA_ALARM_BODY, alarmBody)
                    }

                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_FAILED", e.message, null)
                    }
                }
                "stopService" -> {
                    val intent = Intent(this, PomodoroService::class.java)
                    stopService(intent)
                    cancelAlarm(this)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun cancelAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PomodoroAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }
}

