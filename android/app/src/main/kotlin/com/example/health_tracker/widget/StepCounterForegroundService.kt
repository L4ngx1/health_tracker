package com.example.health_tracker.widget

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import com.example.health_tracker.MainActivity
import com.example.health_tracker.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt

class StepCounterForegroundService : Service(), SensorEventListener {
    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        if (stepSensor != null && hasActivityRecognitionPermission()) {
            sensorManager?.registerListener(this, stepSensor, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_STEP_COUNTER) {
            return
        }

        val absoluteSteps = event.values.firstOrNull()?.toInt() ?: return
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val today = dayKey()
        val storedDay = prefs.getString(KEY_BASE_DAY, null)
        val currentBase = prefs.getInt(KEY_BASE_SENSOR, -1)

        val editor = prefs.edit()
        if (storedDay != today || currentBase < 0) {
            editor.putString(KEY_BASE_DAY, today)
            editor.putInt(KEY_BASE_SENSOR, absoluteSteps)
            editor.putInt(KEY_TODAY_STEPS, 0)
            editor.putFloat(KEY_TODAY_DISTANCE_KM, 0f)
            editor.putInt(KEY_TODAY_CALORIES, 0)
            editor.apply()
            StepCounterWidgetProvider.updateAllWidgets(this)
            return
        }

        val todaySteps = max(0, absoluteSteps - currentBase)
        val distanceKm = (todaySteps * STEP_LENGTH_METERS) / 1000.0f
        val calories = resolveFlutterCalories(today) ?: (distanceKm * CALORIES_PER_KM).roundToInt()
        val previous = prefs.getInt(KEY_TODAY_STEPS, 0)
        val previousDistance = prefs.getFloat(KEY_TODAY_DISTANCE_KM, 0f)
        val previousCalories = prefs.getInt(KEY_TODAY_CALORIES, 0)
        if (todaySteps != previous ||
            kotlin.math.abs(distanceKm - previousDistance) > 0.005f ||
            calories != previousCalories
        ) {
            editor.putInt(KEY_TODAY_STEPS, todaySteps)
            editor.putFloat(KEY_TODAY_DISTANCE_KM, distanceKm)
            editor.putInt(KEY_TODAY_CALORIES, calories)
            editor.apply()
            StepCounterWidgetProvider.updateAllWidgets(this)
        }
    }

    private fun dayKey(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    }

    private fun buildNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            2001,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Health Tracker")
            .setContentText("Đang theo dõi bước chân cho widget")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Step Tracking",
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = "Theo dõi bước chân nền cho widget"
        manager.createNotificationChannel(channel)
    }

    private fun hasActivityRecognitionPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return true
        }
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACTIVITY_RECOGNITION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun resolveFlutterCalories(today: String): Int? {
        val flutterPrefs = getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
        val scope = detectActiveScope(flutterPrefs) ?: return null
        val dayKey = flutterPrefs.getString("flutter.tracking.dayKey.$scope", null)
        if (dayKey != today) return null

        val calories = getDoubleFromPrefs(flutterPrefs.all, "flutter.tracking.caloriesKcal.$scope")
        return if (calories > 0) calories.roundToInt() else null
    }

    private fun detectActiveScope(flutterPrefs: android.content.SharedPreferences): String? {
        val today = dayKey()
        val all = flutterPrefs.all
        val prefix = "flutter.tracking.dayKey."

        all.entries.forEach { entry ->
            val key = entry.key
            val value = entry.value as? String
            if (key.startsWith(prefix) && value == today) {
                return key.removePrefix(prefix)
            }
        }

        val guestKey = "${prefix}guest"
        if (all.containsKey(guestKey)) {
            return "guest"
        }

        all.keys.firstOrNull { it.startsWith(prefix) }?.let {
            return it.removePrefix(prefix)
        }

        val distancePrefix = "flutter.tracking.distanceMeters."
        all.keys.firstOrNull { it.startsWith(distancePrefix) }?.let {
            return it.removePrefix(distancePrefix)
        }

        val stepPrefix = "flutter.tracking.steps."
        all.keys.firstOrNull { it.startsWith(stepPrefix) }?.let {
            return it.removePrefix(stepPrefix)
        }

        return null
    }

    private fun getDoubleFromPrefs(all: Map<String, *>, key: String): Double {
        val value = all[key] ?: return 0.0
        return when (value) {
            is Int -> value.toDouble()
            is Long -> value.toDouble()
            is Float -> value.toDouble()
            is Double -> value
            is String -> value.toDoubleOrNull() ?: 0.0
            else -> 0.0
        }
    }

    companion object {
        private const val CHANNEL_ID = "step_tracking_channel"
        private const val NOTIFICATION_ID = 8899

        private const val PREFS_NAME = "health_tracker_widget"
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_BASE_DAY = "base_day"
        private const val KEY_BASE_SENSOR = "base_sensor"
        private const val KEY_TODAY_STEPS = "today_steps"
        private const val KEY_TODAY_DISTANCE_KM = "today_distance_km"
        private const val KEY_TODAY_CALORIES = "today_calories"
        private const val STEP_LENGTH_METERS = 0.78f
        private const val CALORIES_PER_KM = 55f
    }
}
