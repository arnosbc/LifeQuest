package com.example.proyecto_movil

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

  // El toque del widget puede llegar antes de que Flutter escuche (app cerrada
  // por el sistema): se guarda el enlace y la app lo lee al estar lista.
  override fun onCreate(savedInstanceState: Bundle?) {
    stashWidgetLink(intent)
    super.onCreate(savedInstanceState)
  }

  override fun onNewIntent(intent: Intent) {
    stashWidgetLink(intent)
    super.onNewIntent(intent)
  }

  // Al abrir la app el widget recalcula el ánimo de la mascota aunque el Inicio
  // no cargue (sin internet, o pasada la medianoche).
  override fun onResume() {
    super.onResume()
    val ids = AppWidgetManager.getInstance(this)
        .getAppWidgetIds(ComponentName(this, LifeQuestWidgetProvider::class.java))
    if (ids.isEmpty()) return
    sendBroadcast(
        Intent(this, LifeQuestWidgetProvider::class.java)
            .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids))
  }

  private fun stashWidgetLink(intent: Intent?) {
    val link = intent?.data ?: return
    if (intent.action != HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION) return
    // Mismo archivo que HomeWidget.getWidgetData (home_widget).
    getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        .edit()
        .putString("pending_link", link.toString())
        .apply()
  }
}
