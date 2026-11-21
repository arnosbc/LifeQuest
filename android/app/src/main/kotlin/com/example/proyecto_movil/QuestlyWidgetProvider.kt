package com.example.proyecto_movil

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
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
 * Widget de inicio: la mascota con la racha y el progreso de hoy (tareas y
 * hábitos). Los datos los escribe la app (lib/app/home_widget_sync.dart); el
 * ánimo de la mascota sale de [widgetMood] con esos datos y la hora actual, así
 * que cambia aunque no se abra la app (se redibuja cada 30 min). Tocarlo abre
 * la app.
 */
class QuestlyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val signedIn = widgetData.getBoolean("signed_in", false)
        val streak = widgetData.getInt("streak", 0)
        val savedDay = widgetData.getString("saved_day", null)
            ?.let { runCatching { LocalDate.parse(it) }.getOrNull() }
        val zone = ZoneId.systemDefault()
        val now = ZonedDateTime.now(zone)
        val today = now.toLocalDate()
        // Lo guardado de un día anterior ya no vale para hoy.
        val isToday = savedDay == today
        val done = if (isToday) widgetData.getInt("done", 0) else 0
        val total = if (isToday) widgetData.getInt("total", 0) else 0
        val dayDone = widgetData.getBoolean("day_done", false)
        val pending = (total - done).coerceAtLeast(0)
        val msLeft = Duration.between(now, today.plusDays(1).atStartOfDay(zone)).toMillis()
        val minutesLeft = msLeft / 60_000
        val mood = widgetMood(signedIn, savedDay, today, dayDone, streak, minutesLeft)

        // Tono de invitación (CLAUDE.md §7): ninguna frase culpa.
        val phrase = when (mood) {
            WidgetMood.SIGNED_OUT -> "Toca para entrar"
            WidgetMood.HAPPY -> "¡Día completo!"
            WidgetMood.WAITING -> if (done > 0) "¡Sigue así!" else "¡Tu día te espera!"
            WidgetMood.WORRIED -> if (streak > 0) "Tu racha te espera" else "Aún estás a tiempo"
            WidgetMood.SAD -> "Aún puedes salvar tu racha"
            WidgetMood.SLEEPY -> "Toca para volver"
        }
        val mascot = when (mood) {
            WidgetMood.HAPPY -> R.drawable.widget_mascot_happy
            WidgetMood.WORRIED -> R.drawable.widget_mascot_worried
            WidgetMood.SAD -> R.drawable.widget_mascot_sad
            WidgetMood.SLEEPY -> R.drawable.widget_mascot_sleepy
            WidgetMood.SIGNED_OUT, WidgetMood.WAITING -> R.drawable.widget_mascot_waiting
        }
        // La barra de hoy solo tiene sentido si el día está en juego.
        val countdown = mood == WidgetMood.WORRIED
        val showProgress = signedIn && total > 0 &&
            (mood == WidgetMood.HAPPY || mood == WidgetMood.WAITING || countdown)
        val label = when {
            mood != WidgetMood.HAPPY && pending == 1 -> "Te falta 1"
            mood != WidgetMood.HAPPY && pending > 1 -> "Te faltan $pending"
            else -> "$done de $total hechas hoy"
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.questly_widget).apply {
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setImageViewResource(R.id.mascot, mascot)
                setTextViewText(R.id.streak, if (streak == 1) "1 día" else "$streak días")
                setTextViewText(R.id.phrase, phrase)
                setViewVisibility(R.id.progress_pill, if (showProgress) View.VISIBLE else View.GONE)
                setProgressBar(R.id.progress, maxOf(total, 1), done.coerceIn(0, maxOf(total, 1)), false)
                setTextViewText(R.id.progress_label, label)
                setViewVisibility(R.id.progress_label, if (countdown) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.countdown, if (countdown) View.VISIBLE else View.GONE)
                // Corre sola hasta medianoche sin redibujar el widget.
                setChronometer(R.id.countdown, SystemClock.elapsedRealtime() + msLeft, "Quedan %s", countdown)
                setChronometerCountDown(R.id.countdown, true)
                setContentDescription(
                    R.id.widget_container,
                    "Questly. Racha de $streak días. $phrase. $done de $total hechas hoy.",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
