package com.example.baiuoiki;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import android.content.SharedPreferences;

public class HealthWidgetProvider extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        int steps = prefs.getInt("steps", 0);
        float distance = prefs.getFloat("distance", 0f);
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.health_widget);
            views.setTextViewText(R.id.tv_steps, "Bước chân: " + steps);
            views.setTextViewText(R.id.tv_distance, String.format("Quãng đường: %.2f km", distance / 1000.0));
            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
