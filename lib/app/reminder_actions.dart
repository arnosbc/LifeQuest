import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';

import 'package:proyecto_movil/app/background_boot.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/complete_good_habit.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/complete_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/snooze_task.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_local_datasource.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';
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
  static void sync() => unawaited(syncNow());

  /// Como [sync], pero espera y devuelve lo programado (null si falló).
  static Future<List<LocalReminder>?> syncNow() async {
    if (kIsWeb) return null;
    final result = await sl<SyncReminders>()(_quietUntil);
    final list = result.getRight().toNullable();
    if (list != null) scheduled = list;
    return list;
  }

  /// Avisos programados en la última sincronización; null hasta la primera.
  static List<LocalReminder>? scheduled;

  /// «Te aviso mañana a las 18:50.» para el aviso nuevo (en [after] y no en
  /// [before]) más útil; null si no hay ninguno.
  static String? newReminderText(
    List<LocalReminder> before,
    List<LocalReminder> after,
    DateTime now,
  ) {
    final old = {for (final r in before) r.withId(0)};
    // Primero el aviso de lo que se creó (tarea, hábito, proyecto); el
    // resumen del día o el cierre solo si no hay otro.
    int rank(LocalReminder r) => r.kind == null ? 0 : 1;
    final fresh =
        [
          for (final r in after)
            if (!old.contains(r.withId(0))) r,
        ]..sort((a, b) {
          final byKind = rank(a).compareTo(rank(b));
          return byKind != 0 ? byKind : a.at.compareTo(b.at);
        });
    if (fresh.isEmpty) return null;
    final at = fresh.first.at;
    final days = DateTime(
      at.year,
      at.month,
      at.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    final day = switch (days) {
      0 => 'hoy',
      1 => 'mañana',
      _ => 'el ${_weekdays[at.weekday - 1]}',
    };
    return 'Te aviso $day a las ${at.hour}:${at.minute.toString().padLeft(2, '0')}.';
  }

  static const _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  /// Fin de la sesión de Foco en curso: hasta entonces lo no crítico espera.
  /// Foco lo pone al empezar cada fase y lo quita (null) al terminar.
  static void quietUntil(DateTime? end) {
    if (end == _quietUntil) return;
    _quietUntil = end;
    sync();
  }

  static DateTime? _quietUntil;

  /// Confirmación arriba, como notificación del teléfono. Devuelve false si
  /// el teléfono no las deja mostrar (quien llama avisa dentro de la app).
  static Future<bool> confirm(String title, String body) async {
    if (kIsWeb) return false;
    final plugin = sl<FlutterLocalNotificationsPlugin>();
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() != true) return false;
    // id 0: los avisos programados empiezan en 1 y no lo pisan.
    await plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: RemindersLocalDataSourceImpl.instantDetails,
    );
    return true;
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
        'today' => RoutePaths.home,
        'streak' => RoutePaths.habits,
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
      // Sin return: abajo se sincroniza y se va el aviso de racha de hoy.
      case RemindersLocalDataSourceImpl.actionDone:
        await sl<CompleteTask>()(id);
      case RemindersLocalDataSourceImpl.actionSnooze:
        await sl<SnoozeTask>()((id: id, minutes: 60));
      default:
        return;
    }
    // Completar puede crear la siguiente repetición y posponer mueve el aviso.
    await syncNow();
  }
}

/// Botón pulsado con la app cerrada: corre en otro isolate, sin main().
@pragma('vm:entry-point')
Future<void> onBackgroundResponse(NotificationResponse response) async {
  if (await bootInBackground()) await ReminderActions._handle(response);
}
