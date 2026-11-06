import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';

/// Avisos locales del teléfono (flutter_local_notifications). Lanza
/// [CacheException].
abstract class RemindersLocalDataSource {
  /// Zona IANA del teléfono, p. ej. `America/Bogota`.
  Future<String> timeZone();

  Future<void> replaceAll(List<LocalReminder> reminders);
}

class RemindersLocalDataSourceImpl implements RemindersLocalDataSource {
  RemindersLocalDataSourceImpl(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _zonesLoaded = false;

  /// Ids de los botones; los atiende `app/reminder_actions.dart`.
  static const actionDone = 'done';
  static const actionSnooze = 'snooze';

  static const _channelId = 'reminders';
  static const _channelName = 'Recordatorios';
  static const _channelDescription = 'Avisos de tareas y hábitos con hora';

  @override
  Future<String> timeZone() async {
    try {
      if (!_zonesLoaded) {
        tzdata.initializeTimeZones();
        _zonesLoaded = true;
      }
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
      return name;
    } on Exception catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<void> replaceAll(List<LocalReminder> reminders) async {
    try {
      await _plugin.cancelAll();
      if (reminders.isEmpty) return;
      // Android 13+: pide permiso la primera vez que hay algo que avisar.
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: tz.TZDateTime.from(r.at, tz.local),
          payload: r.taskId,
          // Inexacta: no necesita el permiso de alarma exacta.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: r.weekly
              ? DateTimeComponents.dayOfWeekAndTime
              : null,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
              actions: r.taskId == null
                  ? null
                  : const [
                      AndroidNotificationAction(actionDone, 'Hecha'),
                      AndroidNotificationAction(actionSnooze, 'Posponer 1 h'),
                    ],
            ),
          ),
        );
      }
    } on Exception catch (error) {
      throw CacheException(error.toString());
    }
  }
}
