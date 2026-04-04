package com.example.health_tracker

import android.content.Intent
import android.os.Build
import com.example.health_tracker.widget.StepCounterWidgetProvider
import com.example.health_tracker.widget.StepCounterForegroundService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"health_tracker/widget_sync",
		).setMethodCallHandler { call, result ->
			if (call.method == "updateDistanceWidget") {
				val steps = (call.argument<Number>("steps") ?: 0).toInt()
				val distanceKm = (call.argument<Number>("distanceKm") ?: 0.0).toFloat()
				val calories = (call.argument<Number>("calories") ?: 0).toInt()
				val goalKm = (call.argument<Number>("goalKm") ?: 6.0).toFloat()
				val dayKey = call.argument<String>("dayKey") ?: ""

				val prefs = getSharedPreferences("health_tracker_widget", MODE_PRIVATE)
				prefs.edit()
					.putInt("today_steps", steps)
					.putFloat("today_distance_km", distanceKm)
					.putInt("today_calories", calories)
					.putFloat("goal_km", goalKm)
					.putString("today_day_key", dayKey)
					.apply()

				StepCounterWidgetProvider.updateAllWidgets(this)
				result.success(null)
			} else {
				result.notImplemented()
			}
		}
	}

	override fun onStart() {
		super.onStart()
		val serviceIntent = Intent(this, StepCounterForegroundService::class.java)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			startForegroundService(serviceIntent)
		} else {
			startService(serviceIntent)
		}
	}
}
