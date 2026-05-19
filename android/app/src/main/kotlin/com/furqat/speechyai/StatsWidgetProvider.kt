package com.furqat.speechyai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StatsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.stats_widget)

            val streak = widgetData.getLong("streak", 0)
            val level = widgetData.getLong("level", 1)
            val levelTitle = widgetData.getString("levelTitle", "Beginner") ?: "Beginner"
            val totalXp = widgetData.getLong("totalXp", 0)
            val totalSessions = widgetData.getLong("totalSessions", 0)
            val xpProgress = widgetData.getFloat("xpProgress", 0f)

            views.setTextViewText(R.id.streak_text, "\uD83D\uDD25 $streak day streak")
            views.setTextViewText(R.id.level_text, "Lvl $level")
            views.setTextViewText(R.id.level_title_text, levelTitle)
            views.setTextViewText(R.id.xp_text, "${formatNumber(totalXp)} XP")
            views.setTextViewText(R.id.sessions_text, "$totalSessions sessions")
            views.setTextViewText(R.id.progress_label, "\u2192 Lvl ${level + 1}")

            val progressPercent = (xpProgress * 100).toInt().coerceIn(0, 100)
            views.setProgressBar(R.id.progress_bar, 100, progressPercent, false)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.stats_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun formatNumber(n: Long): String {
        return if (n >= 1000) {
            String.format("%,d", n)
        } else {
            n.toString()
        }
    }
}
