package com.example.proyecto_movil

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget «Mi día»: dibuja lo que la app guardó con HomeWidget.saveWidgetData
 * (home_screen_widget.dart). Tocarlo abre Inicio; la barra de misiones abre
 * Foco con la siguiente tarea.
 */
class LifeQuestWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val signedIn = widgetData.getBoolean("signed_in", false)
    val streak = widgetData.getInt("streak", 0)
    val done = widgetData.getInt("missions_done", 0)
    val goal = widgetData.getInt("missions_goal", 3).coerceAtLeast(1)
    val taskId = widgetData.getString("next_task_id", null)

    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.lifequest_widget).apply {
        setTextViewText(R.id.widget_streak, if (streak == 1) "1 día" else "$streak días")
        setTextViewText(
            R.id.widget_title,
            when {
              !signedIn -> "Inicia sesión para empezar"
              streak > 0 -> "¡Tu aventura continúa!"
              else -> "¡Empieza tu aventura!"
            },
        )
        setProgressBar(R.id.widget_progress, goal, done.coerceIn(0, goal), false)
        setTextViewText(R.id.widget_missions_text, "$done de $goal misiones de hoy")
        setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("lifequest://home")),
        )
        setOnClickPendingIntent(
            R.id.widget_missions,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(
                    if (signedIn && taskId != null) "lifequest://focus?task=$taskId"
                    else "lifequest://home"),
            ),
        )
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }
}
