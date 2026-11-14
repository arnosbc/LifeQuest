package com.example.proyecto_movil

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetMoodTest {
  private val today = LocalDate.of(2026, 11, 10)
  private val calm = 10 * 60L // 10 h para medianoche
  private val late = 2 * 60L // 2 h para medianoche

  private fun mood(daysAgo: Long, done: Boolean, streak: Int = 5, minutes: Long = calm) =
      widgetMood(true, today.minusDays(daysAgo), today, done, streak, minutes)

  @Test
  fun animos() {
    assertEquals(WidgetMood.SIGNED_OUT, widgetMood(false, today, today, true, 5, calm))
    assertEquals(WidgetMood.SIGNED_OUT, widgetMood(true, null, today, true, 5, calm))
    assertEquals(WidgetMood.HAPPY, mood(0, done = true))
    assertEquals(WidgetMood.HAPPY, mood(0, done = true, minutes = late))
    assertEquals(WidgetMood.WAITING, mood(0, done = false))
    assertEquals(WidgetMood.WORRIED, mood(0, done = false, minutes = late))
    // Ayer cumplido y hoy sin abrir: la racha sigue viva.
    assertEquals(WidgetMood.WAITING, mood(1, done = true))
    assertEquals(WidgetMood.WORRIED, mood(1, done = true, minutes = late))
    // Ayer sin cumplir: racha en pausa dentro de las 48 h.
    assertEquals(WidgetMood.SAD, mood(1, done = false))
    assertEquals(WidgetMood.SAD, mood(2, done = false))
    assertEquals(WidgetMood.SAD, mood(3, done = true))
    // Pasadas las 48 h, o sin racha que salvar, la mascota se duerme.
    assertEquals(WidgetMood.SLEEPY, mood(3, done = false))
    assertEquals(WidgetMood.SLEEPY, mood(2, done = false, streak = 0))
    assertEquals(WidgetMood.WAITING, mood(1, done = false, streak = 0))
  }
}
