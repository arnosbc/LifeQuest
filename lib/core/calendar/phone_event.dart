import 'package:equatable/equatable.dart';

/// Permiso del calendario del teléfono. [notAsked]: se puede pedir con una
/// explicación; [denied]: la app funciona igual, sin eventos.
enum CalendarAccess { granted, notAsked, denied }

/// Evento del calendario del teléfono que ocupa tiempo (sin los de todo el
/// día ni los marcados como libres). Dart puro: lo usan Hoy y el Asistente.
class PhoneEvent extends Equatable {
  const PhoneEvent({
    required this.title,
    required this.start,
    required this.end,
  });

  final String title;
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [title, start, end];
}

/// Contrato del calendario del teléfono. Compartido en core/ porque lo leen
/// dos features (Hoy y el Asistente); la implementación es
/// `DevicePhoneCalendar` (core/calendar/device_phone_calendar.dart).
abstract class PhoneCalendar {
  Future<CalendarAccess> access();

  /// Muestra el permiso del sistema; llamar solo tras explicar para qué.
  Future<CalendarAccess> requestAccess();

  /// Eventos que tocan [from, to). Sin permiso o con error, lista vacía:
  /// el calendario nunca bloquea la app.
  Future<List<PhoneEvent>> events(DateTime from, DateTime to);
}
