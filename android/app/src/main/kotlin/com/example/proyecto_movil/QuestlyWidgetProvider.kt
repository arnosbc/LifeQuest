package com.example.proyecto_movil

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de inicio: las próximas 3 tareas de hoy. Los datos los escribe la app
 * (lib/app/home_widget_sync.dart); «✓» completa la tarea en segundo plano con
 * el callback Dart `onWidgetAction`, sin abrir la app.
 */
class QuestlyWidgetProvider : HomeWidgetProvider() {
    private val rows = listOf(
        Triple(R.id.row0, R.id.row0_time, R.id.row0_title) to R.id.row0_done,
        Triple(R.id.row1, R.id.row1_time, R.id.row1_title) to R.id.row1_done,
        Triple(R.id.row2, R.id.row2_time, R.id.row2_title) to R.id.row2_done,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.questly_widget).apply {
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                val count = widgetData.getInt("count", -1)
                setViewVisibility(R.id.empty, if (count > 0) View.GONE else View.VISIBLE)
                if (count == 0) setTextViewText(R.id.empty, "Nada pendiente hoy.")
                rows.forEachIndexed { i, (ids, done) ->
                    val (row, time, title) = ids
                    val id = widgetData.getString("task_${i}_id", null)
                    if (i >= count || id == null) {
                        setViewVisibility(row, View.GONE)
                        return@forEachIndexed
                    }
                    setViewVisibility(row, View.VISIBLE)
                    setTextViewText(time, widgetData.getString("task_${i}_time", "") ?: "")
                    setTextViewText(title, widgetData.getString("task_${i}_title", "") ?: "")
                    setContentDescription(done, "Marcar como hecha")
                    setOnClickPendingIntent(
                        done,
                        HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            Uri.parse("questly://done?id=$id"),
                        ),
                    )
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
