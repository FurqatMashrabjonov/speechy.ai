package com.furqat.speechyai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.roundToInt

class RoadmapWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "HomeWidgetPlugin"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            updateWidget(context, appWidgetManager, id, widgetData, options)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        updateWidget(context, appWidgetManager, appWidgetId, data, newOptions)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        data: SharedPreferences,
        options: Bundle
    ) {
        val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)

        // Pick layout tier based on current widget dimensions
        val layoutId = when {
            minH < 70 -> R.layout.roadmap_widget_small
            minW < 200 -> R.layout.roadmap_widget_medium
            else -> R.layout.roadmap_widget
        }

        val views = RemoteViews(context.packageName, layoutId)

        // Read data
        val roadmapTitle = data.getString("roadmapTitle", null)
        val currentStep = data.getInt("roadmapCurrentStep", 0)
        val totalSteps = data.getInt("roadmapTotalSteps", 15).coerceAtLeast(1)
        val streak = data.getInt("streak", 0)

        val hasPlan = roadmapTitle != null && currentStep > 0

        // Streak text
        val streakText = when {
            layoutId == R.layout.roadmap_widget_small -> "🔥 $streak"
            streak == 1 -> "🔥 1 day streak"
            streak > 1 -> "🔥 $streak day streak"
            else -> "🔥 Start streak"
        }

        // Populate by layout tier
        when (layoutId) {
            R.layout.roadmap_widget_small -> populateSmall(views, streakText, roadmapTitle, currentStep, totalSteps, hasPlan)
            R.layout.roadmap_widget_medium -> populateMedium(views, streakText, roadmapTitle, currentStep, totalSteps, hasPlan)
            else -> populateFull(views, streakText, roadmapTitle, currentStep, totalSteps, hasPlan)
        }

        // Tap → open app
        val intent = Intent(context, MainActivity::class.java)
        val pending = PendingIntent.getActivity(
            context, 3, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pending)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun populateSmall(
        views: RemoteViews,
        streakText: String,
        title: String?,
        current: Int,
        total: Int,
        hasPlan: Boolean
    ) {
        views.setTextViewText(R.id.streak, streakText)
        if (hasPlan) {
            views.setTextViewText(R.id.track_name, title!!)
            views.setTextViewText(R.id.step_label, "Step $current of $total")
        } else {
            views.setTextViewText(R.id.track_name, "Start your journey →")
            views.setTextViewText(R.id.step_label, "Tap to begin")
        }
    }

    private fun populateMedium(
        views: RemoteViews,
        streakText: String,
        title: String?,
        current: Int,
        total: Int,
        hasPlan: Boolean
    ) {
        views.setTextViewText(R.id.streak, streakText)
        if (hasPlan) {
            views.setTextViewText(R.id.track_name, title!!)
            views.setTextViewText(R.id.step_label, "Step $current of $total")
            val (filled, empty) = buildDots(current, total, maxDots = 10)
            views.setTextViewText(R.id.dots_filled, filled)
            views.setTextViewText(R.id.dots_empty, empty)
        } else {
            views.setTextViewText(R.id.track_name, "Start Your Journey")
            views.setTextViewText(R.id.step_label, "Take the assessment")
            views.setTextViewText(R.id.dots_filled, "")
            views.setTextViewText(R.id.dots_empty, "○○○○○○○○○○")
        }
    }

    private fun populateFull(
        views: RemoteViews,
        streakText: String,
        title: String?,
        current: Int,
        total: Int,
        hasPlan: Boolean
    ) {
        views.setTextViewText(R.id.streak, streakText)
        if (hasPlan) {
            views.setTextViewText(R.id.track_name, title!!)
            views.setTextViewText(R.id.step_label, "Step $current of $total")
            val (filled, empty) = buildDots(current, total, maxDots = 15)
            views.setTextViewText(R.id.dots_filled, filled)
            views.setTextViewText(R.id.dots_empty, empty)
        } else {
            views.setTextViewText(R.id.track_name, "Start Your Journey")
            views.setTextViewText(R.id.step_label, "Take the 5-min assessment")
            views.setTextViewText(R.id.dots_filled, "")
            views.setTextViewText(R.id.dots_empty, "○○○○○○○○○○○○○○○")
        }
    }

    /**
     * Returns (filledDots, emptyDots) scaled to maxDots display slots.
     * Completed step N means steps 1..N-1 are done (current is in progress).
     */
    private fun buildDots(current: Int, total: Int, maxDots: Int): Pair<String, String> {
        val display = total.coerceAtMost(maxDots)
        val completedSteps = (current - 1).coerceAtLeast(0)
        val filledCount = if (total <= maxDots) {
            completedSteps.coerceAtMost(display)
        } else {
            (completedSteps.toDouble() / total * maxDots).roundToInt().coerceAtMost(display)
        }
        val emptyCount = (display - filledCount).coerceAtLeast(0)
        return Pair("●".repeat(filledCount), "○".repeat(emptyCount))
    }
}
