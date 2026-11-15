package com.example.proyecto_movil

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.Duration
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Widget «Mi día»: dibuja lo que la app guardó con HomeWidget.saveWidgetData
 * (home_screen_widget.dart). La mascota cambia de ánimo según si el día está
 * cumplido, cuánto falta para medianoche y cuántos días lleva sin abrir la app
 * (widgetMood). Se redibuja solo cada 30 min (lifequest_widget_info.xml).
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
    val goal = widgetData.getInt("missions_goal", 3).coerceAtLeast(1)
    val taskId = widgetData.getString("next_task_id", null)
    val savedDay = widgetData.getString("saved_day", null)
        ?.let { runCatching { LocalDate.parse(it) }.getOrNull() }
    val zone = ZoneId.systemDefault()
    val now = ZonedDateTime.now(zone)
    val today = now.toLocalDate()
    val isSavedToday = savedDay == today
    // Lo guardado de un día anterior ya no vale para hoy.
    val done = if (isSavedToday) widgetData.getInt("missions_done", 0) else 0
    val pending = if (isSavedToday) widgetData.getInt("pending", 0) else 0
    // Meta diaria de XP (063): si la hay, la barra mide XP en vez de misiones.
    val xpGoal = widgetData.getInt("xp_goal", 0)
    val xpDone = if (isSavedToday) widgetData.getInt("xp_done", 0) else 0
    val barMax = if (xpGoal > 0) xpGoal else goal
    val barValue = if (xpGoal > 0) xpDone else done
    val dayDone = widgetData.getBoolean("day_done", false)
    val msLeft = Duration.between(now, today.plusDays(1).atStartOfDay(zone)).toMillis()
    val mood = widgetMood(signedIn, savedDay, today, dayDone, streak, msLeft / 60_000)

    val title = when (mood) {
      WidgetMood.SIGNED_OUT -> "Inicia sesión"
      WidgetMood.HAPPY -> "¡Día cumplido!"
      WidgetMood.WAITING -> if (streak > 0) "Tu racha te espera" else "¡Empieza tu aventura!"
      WidgetMood.WORRIED -> if (streak > 0) "¡Tu racha te espera!" else "¡Aún estás a tiempo!"
      WidgetMood.SAD -> "Racha en pausa"
      WidgetMood.SLEEPY -> "¡Te extrañamos!"
    }
    val detail = when (mood) {
      WidgetMood.SIGNED_OUT -> "Toca para entrar"
      WidgetMood.SAD -> "¡Aún puedes salvarla!"
      WidgetMood.SLEEPY -> "Toca para volver"
      else -> when {
        mood != WidgetMood.HAPPY && pending == 1 -> "Te falta 1 cosa"
        mood != WidgetMood.HAPPY && pending > 1 -> "Te faltan $pending cosas"
        xpGoal > 0 -> "$xpDone de $xpGoal XP hoy"
        else -> "$done de $goal misiones"
      }
    }
    val mascot = when (mood) {
      WidgetMood.HAPPY -> R.drawable.widget_mascot_happy
      WidgetMood.WORRIED -> R.drawable.widget_mascot_worried
      WidgetMood.SAD -> R.drawable.widget_mascot_sad
      WidgetMood.SLEEPY -> R.drawable.widget_mascot_sleepy
      WidgetMood.SIGNED_OUT, WidgetMood.WAITING -> R.drawable.widget_mascot_waiting
    }
    val countdown = mood == WidgetMood.WORRIED
    // La barra de misiones de hoy solo tiene sentido si el día está en juego.
    val showProgress = mood == WidgetMood.HAPPY || mood == WidgetMood.WAITING || countdown

    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.lifequest_widget).apply {
        setTextViewText(R.id.widget_streak, if (streak == 1) "1 día" else "$streak días")
        setTextViewText(R.id.widget_title, title)
        setImageViewResource(R.id.widget_mascot, mascot)
        setContentDescription(R.id.widget_mascot, "Mascota: $title")
        setProgressBar(R.id.widget_progress, barMax, barValue.coerceIn(0, barMax), false)
        setViewVisibility(R.id.widget_progress, if (showProgress) View.VISIBLE else View.GONE)
        setTextViewText(R.id.widget_missions_text, detail)
        setViewVisibility(R.id.widget_missions_text, if (countdown) View.GONE else View.VISIBLE)
        setViewVisibility(R.id.widget_countdown, if (countdown) View.VISIBLE else View.GONE)
        // Cuenta atrás en vivo hasta medianoche; corre sola sin redibujar el widget.
        setChronometer(
            R.id.widget_countdown, SystemClock.elapsedRealtime() + msLeft, "Quedan %s", countdown)
        setChronometerCountDown(R.id.widget_countdown, true)
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
