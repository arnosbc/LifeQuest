package com.example.proyecto_movil

import java.time.LocalDate
import java.time.temporal.ChronoUnit

/** Ánimo de la mascota del widget «Mi día». */
enum class WidgetMood { SIGNED_OUT, HAPPY, WAITING, WORRIED, SAD, SLEEPY }

/** Horas antes de medianoche en que la mascota se preocupa y aparece la cuenta atrás. */
const val WORRY_HOURS = 4L

/**
 * Elige el ánimo con lo último que guardó la app ([savedDay]) y la hora actual,
 * para que el widget cambie aunque el usuario no abra la app.
 */
fun widgetMood(
    signedIn: Boolean,
    savedDay: LocalDate?,
    today: LocalDate,
    dayDone: Boolean,
    streak: Int,
    minutesLeft: Long,
): WidgetMood {
  if (!signedIn || savedDay == null) return WidgetMood.SIGNED_OUT
  val daysAway = ChronoUnit.DAYS.between(savedDay, today)
  // Último día cumplido: el guardado, o el anterior si la racha seguía viva.
  val lastDone = if (dayDone) savedDay else savedDay.minusDays(1)
  val missedDays = ChronoUnit.DAYS.between(lastDone, today) - 1
  return when {
    dayDone && daysAway == 0L -> WidgetMood.HAPPY
    // Hay 48 h para recuperar una racha rota (§13).
    streak > 0 && missedDays in 1L..2L -> WidgetMood.SAD
    daysAway >= 2L -> WidgetMood.SLEEPY
    minutesLeft < WORRY_HOURS * 60 -> WidgetMood.WORRIED
    else -> WidgetMood.WAITING
  }
}
