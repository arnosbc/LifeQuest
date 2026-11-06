import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/app/config/constants.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/complete_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/snooze_mission.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_local_datasource.dart';
import 'package:proyecto_movil/features/reminders/domain/usecases/sync_reminders.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Botones Hecha / Posponer 1 h de los avisos de tareas. Une Recordatorios
/// con Tareas, por eso vive en app/ (una feature no importa otra).
abstract final class ReminderActions {
  /// Llamar en main() después de initDependencies().
  static Future<void> init() =>
      sl<FlutterLocalNotificationsPlugin>().initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: _handle,
        onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
      );

  /// Vuelve a programar los avisos (al iniciar sesión, al volver a la app y
  /// cuando cambian las tareas). Si falla, quedan los avisos anteriores.
  static void sync() => unawaited(sl<SyncReminders>()(const NoParams()));

  /// Al cerrar sesión: que no queden avisos de la cuenta anterior.
  static void clear() =>
      unawaited(sl<FlutterLocalNotificationsPlugin>().cancelAll());

  static Future<void> _handle(NotificationResponse response) async {
    final taskId = response.payload;
    if (taskId == null || taskId.isEmpty) return;
    switch (response.actionId) {
      case RemindersLocalDataSourceImpl.actionDone:
        await sl<CompleteMission>()(taskId);
      case RemindersLocalDataSourceImpl.actionSnooze:
        await sl<SnoozeMission>()((id: taskId, minutes: 60));
      default:
        return; // Tocar el aviso solo abre la app.
    }
    // Completar puede crear la siguiente repetición y posponer mueve el aviso.
    await sl<SyncReminders>()(const NoParams());
  }
}

/// Botón pulsado con la app cerrada: corre en otro isolate, sin main().
@pragma('vm:entry-point')
Future<void> onBackgroundResponse(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  // La sesión guardada se restaura al inicializar Supabase.
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseKey,
  );
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) return;
  if (auth.currentSession!.isExpired) await auth.refreshSession();
  await initDependencies();
  await ReminderActions._handle(response);
}
