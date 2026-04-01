package com.example.health_tracker.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.health_tracker.MainActivity
import com.example.health_tracker.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

enum class WidgetSize {
    SMALL,
    MEDIUM,
    LARGE,
}

private data class WidgetSnapshot(
    val steps: Int,
    val distanceKm: Float,
    val calories: Int,
    val goalKm: Float,
    val progressPercent: Int,
)

abstract class BaseTrackingWidgetProvider : AppWidgetProvider() {
    protected abstract val widgetSize: WidgetSize

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            appWidgetManager.updateAppWidget(
                appWidgetId,
                StepCounterWidgetProvider.buildViews(context, widgetSize),
            )
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == StepCounterWidgetProvider.ACTION_REFRESH_WIDGET) {
            StepCounterWidgetProvider.updateAllWidgets(context)
        }
    }
}

class StepCounterSmallWidgetProvider : BaseTrackingWidgetProvider() {
    override val widgetSize: WidgetSize = WidgetSize.SMALL
}

class StepCounterWidgetProvider : BaseTrackingWidgetProvider() {
    override val widgetSize: WidgetSize = WidgetSize.MEDIUM

    companion object {
        const val ACTION_REFRESH_WIDGET = "com.example.health_tracker.ACTION_REFRESH_WIDGET"
        private const val PREFS_NAME = "health_tracker_widget"
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_TODAY_STEPS = "today_steps"
        private const val KEY_TODAY_DISTANCE_KM = "today_distance_km"
        private const val KEY_TODAY_CALORIES = "today_calories"
        private const val KEY_TODAY_DAY_KEY = "today_day_key"
        private const val KEY_GOAL_KM = "goal_km"
        private const val DEFAULT_GOAL_KM = 6.0f

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val providers = listOf(
                Pair(StepCounterSmallWidgetProvider::class.java, WidgetSize.SMALL),
                Pair(StepCounterWidgetProvider::class.java, WidgetSize.MEDIUM),
                Pair(StepCounterLargeWidgetProvider::class.java, WidgetSize.LARGE),
            )

            providers.forEach { (providerClass, size) ->
                val componentName = ComponentName(context, providerClass)
                val ids = manager.getAppWidgetIds(componentName)
                ids.forEach { appWidgetId ->
                    manager.updateAppWidget(appWidgetId, buildViews(context, size))
                }
            }
        }

        fun buildViews(context: Context, size: WidgetSize): RemoteViews {
            val data = loadSnapshot(context)
            return when (size) {
                WidgetSize.SMALL -> buildSmallViews(context, data)
                WidgetSize.MEDIUM -> buildMediumViews(context, data)
                WidgetSize.LARGE -> buildLargeViews(context, data)
            }
        }

        private fun loadSnapshot(context: Context): WidgetSnapshot {
            val fallbackPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            val all = flutterPrefs.all
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

            val syncedDayKey = fallbackPrefs.getString(KEY_TODAY_DAY_KEY, null)
            val useDirectSyncedValues = syncedDayKey == today
            if (useDirectSyncedValues) {
                val distanceKm = fallbackPrefs.getFloat(KEY_TODAY_DISTANCE_KM, 0f)
                val todaySteps = fallbackPrefs.getInt(KEY_TODAY_STEPS, 0)
                val calories = fallbackPrefs.getInt(KEY_TODAY_CALORIES, 0)
                val goalKm = fallbackPrefs.getFloat(KEY_GOAL_KM, DEFAULT_GOAL_KM)
                val safeGoalKm = if (goalKm <= 0f) DEFAULT_GOAL_KM else goalKm
                val progressPercent =
                    ((distanceKm / safeGoalKm) * 100f).coerceIn(0f, 999f).toInt()

                return WidgetSnapshot(
                    steps = todaySteps,
                    distanceKm = distanceKm,
                    calories = calories,
                    goalKm = safeGoalKm,
                    progressPercent = progressPercent,
                )
            }

            val scope = detectActiveScope(flutterPrefs)
            val hasFlutterTracking = scope != null

            val distanceMeters = if (hasFlutterTracking) {
                getDoubleFromPrefs(all, "flutter.tracking.distanceMeters.$scope")
            } else {
                (fallbackPrefs.getFloat(KEY_TODAY_DISTANCE_KM, 0f) * 1000.0)
            }

            val distanceKm = (distanceMeters / 1000.0).toFloat()
            val todaySteps = if (hasFlutterTracking) {
                getIntFromPrefs(all, "flutter.tracking.steps.$scope")
            } else {
                (distanceMeters / 0.78).roundToInt()
            }
            val calories = (distanceKm * 55f).roundToInt()

            val goalKm = if (hasFlutterTracking) {
                getDoubleFromPrefs(all, "flutter.home.movementGoalKm.$scope").toFloat()
            } else {
                fallbackPrefs.getFloat(KEY_GOAL_KM, DEFAULT_GOAL_KM)
            }
            val safeGoalKm = if (goalKm <= 0f) DEFAULT_GOAL_KM else goalKm
            val progressPercent =
                ((distanceKm / safeGoalKm) * 100f).coerceIn(0f, 999f).toInt()

            return WidgetSnapshot(
                steps = todaySteps,
                distanceKm = distanceKm,
                calories = calories,
                goalKm = safeGoalKm,
                progressPercent = progressPercent,
            )
        }

        private fun buildSmallViews(context: Context, data: WidgetSnapshot): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.step_counter_widget_small)
            views.setTextViewText(R.id.widgetSmallPercent, "${data.progressPercent}%")
            views.setTextViewText(R.id.widgetSmallSteps, formatInt(data.steps))
            views.setOnClickPendingIntent(
                R.id.widgetSmallContainer,
                createLaunchPendingIntent(context, 2101),
            )
            return views
        }

        private fun buildMediumViews(context: Context, data: WidgetSnapshot): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.step_counter_widget)
            views.setTextViewText(R.id.widgetMediumTime, "HOM NAY, ${timeLabel()}")
            views.setTextViewText(R.id.widgetMediumDistanceValue, String.format(Locale.US, "%.1f", data.distanceKm))
            views.setTextViewText(R.id.widgetMediumStepsValue, formatCompactSteps(data.steps))
            views.setTextViewText(R.id.widgetMediumCaloriesValue, data.calories.toString())
            views.setProgressBar(R.id.widgetMediumProgressBar, 100, data.progressPercent.coerceIn(0, 100), false)
            views.setTextViewText(R.id.widgetMediumProgressText, "${data.progressPercent}% muc tieu")
            views.setOnClickPendingIntent(
                R.id.widgetContainer,
                createLaunchPendingIntent(context, 2102),
            )
            return views
        }

        private fun buildLargeViews(context: Context, data: WidgetSnapshot): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.step_counter_widget_large)
            views.setTextViewText(R.id.widgetLargeProgressChip, "${data.progressPercent}% MUC TIEU")
            views.setTextViewText(R.id.widgetLargeDistanceValue, String.format(Locale.US, "%.1f", data.distanceKm))
            views.setTextViewText(R.id.widgetLargeStepsValue, formatCompactSteps(data.steps))
            views.setTextViewText(R.id.widgetLargeCaloriesValue, data.calories.toString())
            views.setProgressBar(R.id.widgetLargeProgressBar, 100, data.progressPercent.coerceIn(0, 100), false)
            views.setTextViewText(
                R.id.widgetLargeFooter,
                String.format(Locale.US, "Muc tieu %.1f km • %s buoc", data.goalKm, formatInt(data.steps)),
            )
            views.setOnClickPendingIntent(
                R.id.widgetLargeContainer,
                createLaunchPendingIntent(context, 2103),
            )
            return views
        }

        private fun createLaunchPendingIntent(context: Context, requestCode: Int): PendingIntent {
            val launchIntent = Intent(context, MainActivity::class.java)
            return PendingIntent.getActivity(
                context,
                requestCode,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun timeLabel(): String {
            return SimpleDateFormat("HH'H'mm", Locale.US).format(Date())
        }

        private fun formatInt(value: Int): String {
            val raw = String.format(Locale.US, "%,d", value)
            return raw.replace(',', '.')
        }

        private fun formatCompactSteps(steps: Int): String {
            if (steps < 1000) {
                return steps.toString()
            }
            val compact = steps / 1000f
            return String.format(Locale.US, "%.1fK", compact)
        }

        private fun getIntFromPrefs(all: Map<String, *>, key: String): Int {
            val value = all[key] ?: return 0
            return when (value) {
                is Int -> value
                is Long -> value.toInt()
                is Float -> value.toInt()
                is Double -> value.toInt()
                is String -> value.toIntOrNull() ?: 0
                else -> 0
            }
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

        private fun detectActiveScope(flutterPrefs: android.content.SharedPreferences): String? {
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val all = flutterPrefs.all
            val prefix = "flutter.tracking.dayKey."

            // Prefer the scope that has today's tracking key.
            all.entries.forEach { entry ->
                val key = entry.key
                val value = entry.value as? String
                if (key.startsWith(prefix) && value == today) {
                    return key.removePrefix(prefix)
                }
            }

            // Fallback to guest scope when no active user scope is detected.
            val guestKey = "${prefix}guest"
            if (all.containsKey(guestKey)) {
                return "guest"
            }

            // Last fallback: first available scope.
            all.keys.firstOrNull { it.startsWith(prefix) }?.let {
                return it.removePrefix(prefix)
            }

            // If dayKey is absent, fallback by checking tracking distance keys.
            val distancePrefix = "flutter.tracking.distanceMeters."
            all.keys.firstOrNull { it.startsWith(distancePrefix) }?.let {
                return it.removePrefix(distancePrefix)
            }

            // Final fallback by tracking steps keys.
            val stepPrefix = "flutter.tracking.steps."
            all.keys.firstOrNull { it.startsWith(stepPrefix) }?.let {
                return it.removePrefix(stepPrefix)
            }

            return null
        }
    }
}

class StepCounterLargeWidgetProvider : BaseTrackingWidgetProvider() {
    override val widgetSize: WidgetSize = WidgetSize.LARGE
}
