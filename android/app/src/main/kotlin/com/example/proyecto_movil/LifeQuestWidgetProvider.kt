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
 * (home_widget_sync.dart). Tocarlo abre Inicio; el botón abre Foco con la tarea.
 */
class LifeQuestWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val signedIn = widgetData.getBoolean("signed_in", false)
    val taskId = widgetData.getString("next_task_id", null)
    val title = widgetData.getString("next_task_title", null)

    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.lifequest_widget).apply {
        setTextViewText(R.id.widget_streak, "🔥 ${widgetData.getInt("streak", 0)} d")
        setTextViewText(R.id.widget_hp, "❤ ${widgetData.getInt("hp", 0)}")
        setTextViewText(R.id.widget_level, "Nv ${widgetData.getInt("level", 1)}")
        setTextViewText(
            R.id.widget_title,
            when {
              !signedIn -> "Inicia sesión para ver tu día"
              title != null -> title
              else -> "Todo al día. Crea tu siguiente tarea"
            },
        )
        setTextViewText(
            R.id.widget_button,
            if (signedIn && taskId != null) "▶  Empezar en Foco" else "Abrir LifeQuest",
        )
        setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("lifequest://home")),
        )
        setOnClickPendingIntent(
            R.id.widget_button,
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
