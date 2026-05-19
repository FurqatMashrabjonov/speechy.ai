package com.furqat.speechyai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ActivityWidgetProvider : HomeWidgetProvider() {

    // Cell IDs mapped in row-major order: row 0 (Mon) = cells 0-4, row 1 (Tue) = cells 5-9, etc.
    private val cellIds = intArrayOf(
        R.id.cell_0, R.id.cell_1, R.id.cell_2, R.id.cell_3, R.id.cell_4,
        R.id.cell_5, R.id.cell_6, R.id.cell_7, R.id.cell_8, R.id.cell_9,
        R.id.cell_10, R.id.cell_11, R.id.cell_12, R.id.cell_13, R.id.cell_14,
        R.id.cell_15, R.id.cell_16, R.id.cell_17, R.id.cell_18, R.id.cell_19,
        R.id.cell_20, R.id.cell_21, R.id.cell_22, R.id.cell_23, R.id.cell_24,
        R.id.cell_25, R.id.cell_26, R.id.cell_27, R.id.cell_28, R.id.cell_29,
        R.id.cell_30, R.id.cell_31, R.id.cell_32, R.id.cell_33, R.id.cell_34
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.activity_widget)

            val streak = widgetData.getLong("streak", 0)
            val totalSessions = widgetData.getLong("totalSessions", 0)

            // Activity data: comma-separated levels (0-3) for 35 cells
            // Layout: column-major — week0[Mon,Tue,...,Sun], week1[Mon,...], ...
            // But our cells are row-major: row0=Mon(w0-w4), row1=Tue(w0-w4), ...
            // So activityGrid index: dayOfWeek * 5 + weekIndex
            val activityStr = widgetData.getString("activityGrid", null) ?: ""
            val levels = if (activityStr.isNotEmpty()) {
                activityStr.split(",").map { it.trim().toIntOrNull() ?: 0 }
            } else {
                List(35) { 0 }
            }

            views.setTextViewText(R.id.activity_streak, "\uD83D\uDD25 $streak")
            views.setTextViewText(R.id.activity_sessions, "$totalSessions sessions")

            // Set each cell background
            for (i in cellIds.indices) {
                val level = if (i < levels.size) levels[i] else 0
                val bgRes = when (level) {
                    1 -> R.drawable.widget_cell_low
                    2 -> R.drawable.widget_cell_med
                    3 -> R.drawable.widget_cell_high
                    else -> R.drawable.widget_cell_empty
                }
                views.setInt(cellIds[i], "setBackgroundResource", bgRes)
            }

            // Click opens app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.activity_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
