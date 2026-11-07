import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';

import 'package:proyecto_movil/app/background_boot.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/complete_good_habit.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/complete_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/snooze_task.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_local_datasource.dart';
import 'package:proyecto_movil/features/reminders/domain/usecases/sync_reminders.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Botones Hecha / Posponer 1 h de los avisos de tareas y Hecho de los
/// hábitos. Une Recordatorios con Tareas y Hábitos, por eso vive en app/
/// (una feature no importa otra).
abstract final class ReminderActions {
  /// Llamar en main() después de initDependencies().
  static Future<void> init() async {
    final plugin = sl<FlutterLocalNotificationsPlugin>();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handle,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
    // La app estaba cerrada y se abrió tocando un aviso.
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      opened.value = routeFor(launch?.notificationResponse?.payload);
    }
  }

  /// Vuelve a programar los avisos (al iniciar sesión, al volver a la app y
  /// cuando cambian las tareas). Si falla, quedan los avisos anteriores.
  static void sync() {
    if (!kIsWeb) unawaited(sl<SyncReminders>()(const NoParams()));
  }

  /// Al cerrar sesión: que no queden avisos de la cuenta anterior.
  static void clear() {
    if (!kIsWeb) unawaited(sl<FlutterLocalNotificationsPlugin>().cancelAll());
  }

  /// Pantalla que pidió abrir un toque en un aviso; la consume `App`.
  static final opened = ValueNotifier<String?>(null);

  /// Ruta de la app para un payload (`task:<id>`, `habit:<id>`, …).
  static String? routeFor(String? payload) =>
      switch (payload?.split(':').first) {
        'task' => RoutePaths.tasks,
        'habit' => RoutePaths.habits,
        'project' => RoutePaths.stage,
        'close' => RoutePaths.review,
        _ => null,
      };

  static Future<void> _handle(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (response.actionId == null) {
      // Tocar el aviso (no un botón): abrir donde se resuelve.
      opened.value = routeFor(payload);
      return;
    }
    final id = payload.substring(payload.indexOf(':') + 1);
    switch (response.actionId) {
      case RemindersLocalDataSourceImpl.actionHabitDone:
        // Si ya estaba hecho hoy, el servidor lo rechaza (already_completed, 005): no cobra dos veces.
        await sl<CompleteGoodHabit>()(
          CompleteGoodHabitParams(habitId: id, now: DateTime.now()),
        );
        return;
      case RemindersLocalDataSourceImpl.actionDone:
        await sl<CompleteTask>()(id);
      case RemindersLocalDataSourceImpl.actionSnooze:
        await sl<SnoozeTask>()((id: id, minutes: 60));
      default:
        return;
    }
    // Completar puede crear la siguiente repetición y posponer mueve el aviso.
    await sl<SyncReminders>()(const NoParams());
  }
}

/// Botón pulsado con la app cerrada: corre en otro isolate, sin main().
@pragma('vm:entry-point')
Future<void> onBackgroundResponse(NotificationResponse response) async {
  if (await bootInBackground()) await ReminderActions._handle(response);
}
