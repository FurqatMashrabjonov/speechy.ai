package com.furqat.speechyai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class RoadmapWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.roadmap_widget)

            val roadmapTitle = widgetData.getString("roadmapTitle", null)
            val currentStep = widgetData.getLong("roadmapCurrentStep", 0).toInt()
            val totalSteps = widgetData.getLong("roadmapTotalSteps", 15).toInt()
            val streak = widgetData.getLong("streak", 0)
            val totalXp = widgetData.getLong("totalXp", 0)
            val level = widgetData.getLong("level", 1)

            if (roadmapTitle != null) {
                val progress = if (totalSteps > 0) (currentStep * 100 / totalSteps) else 0
                views.setTextViewText(R.id.roadmap_title, roadmapTitle)
                views.setTextViewText(R.id.roadmap_step, "Step $currentStep of $totalSteps")
                views.setProgressBar(R.id.roadmap_progress, 100, progress, false)
            } else {
                views.setTextViewText(R.id.roadmap_title, "Start your journey")
                views.setTextViewText(R.id.roadmap_step, "Tap to take the assessment")
                views.setProgressBar(R.id.roadmap_progress, 100, 0, false)
            }

            views.setTextViewText(R.id.roadmap_streak, "🔥 $streak day streak")
            views.setTextViewText(R.id.roadmap_xp, "⚡ $totalXp XP")
            views.setTextViewText(R.id.roadmap_level, "Lv $level")

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 3, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.roadmap_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
