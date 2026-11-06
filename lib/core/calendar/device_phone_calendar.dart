import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyecto_movil/core/calendar/phone_event.dart';

/// [PhoneCalendar] con device_calendar_plus (Calendar Provider en Android).
class DevicePhoneCalendar implements PhoneCalendar {
  DevicePhoneCalendar(this._prefs, {DeviceCalendar? plugin})
    : _plugin = plugin ?? DeviceCalendar.instance;

  final SharedPreferencesAsync _prefs;
  final DeviceCalendar _plugin;

  /// Android no distingue «no preguntado» de «negado» antes de pedirlo:
  /// se recuerda si ya se pidió una vez.
  static const _askedKey = 'calendar_permission_asked';

  @override
  Future<CalendarAccess> access() async {
    try {
      final status = await _plugin.hasPermissions();
      if (status == CalendarPermissionStatus.granted) {
        return CalendarAccess.granted;
      }
    } on Exception {
      // Sin calendario o sin plugin (p. ej. en tests): como negado.
    }
    return await _prefs.getBool(_askedKey) ?? false
        ? CalendarAccess.denied
        : CalendarAccess.notAsked;
  }

  @override
  Future<CalendarAccess> requestAccess() async {
    await _prefs.setBool(_askedKey, true);
    try {
      final status = await _plugin.requestPermissions();
      return status == CalendarPermissionStatus.granted
          ? CalendarAccess.granted
          : CalendarAccess.denied;
    } on Exception {
      return CalendarAccess.denied;
    }
  }

  @override
  Future<List<PhoneEvent>> events(DateTime from, DateTime to) async {
    if (await access() != CalendarAccess.granted) return const [];
    try {
      final events = await _plugin.listEvents(from, to);
      return [
        for (final e in events)
          if (!e.isAllDay &&
              e.availability != EventAvailability.free &&
              e.endDate.isAfter(from) &&
              e.startDate.isBefore(to))
            PhoneEvent(
              title: e.title.trim().isEmpty ? 'Evento' : e.title.trim(),
              start: e.startDate.toLocal(),
              end: e.endDate.toLocal(),
            ),
      ]..sort((a, b) => a.start.compareTo(b.start));
    } on Exception {
      return const [];
    }
  }
}
