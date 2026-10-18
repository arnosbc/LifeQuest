import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Formato de cifras y fechas del Home, en español.
abstract final class HomeFormat {
  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// 12450 → "12.450".
  static String number(int value) {
    final digits = value.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return value < 0 ? '-$digits' : digits;
  }

  /// 45 → "45 min"; 75 → "1 h 15 min".
  static String minutes(int total) {
    if (total < 60) return '$total min';
    final rest = total % 60;
    return rest == 0 ? '${total ~/ 60} h' : '${total ~/ 60} h $rest min';
  }

  static String priority(UrgencyLevel level) => switch (level) {
    UrgencyLevel.high => 'Prioridad alta',
    UrgencyLevel.medium => 'Prioridad media',
    UrgencyLevel.low => 'Prioridad baja',
  };

  /// "Hoy · 18:00", "Mañana · 09:30", "12 oct · 18:00" o, si ya pasó,
  /// "Pendiente desde el 12 oct" (sin culpa, solo el dato).
  static String due(DateTime? due, DateTime now) {
    if (due == null) return 'Sin fecha límite';
    // En UTC para que un cambio de horario no altere la resta de días.
    final day = DateTime.utc(due.year, due.month, due.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final time =
        '${due.hour.toString().padLeft(2, '0')}:'
        '${due.minute.toString().padLeft(2, '0')}';
    final date = '${due.day} ${_months[due.month - 1]}';
    if (due.isBefore(now)) {
      return day == today ? 'Era para hoy · $time' : 'Pendiente desde el $date';
    }
    return switch (day.difference(today).inDays) {
      0 => 'Hoy · $time',
      1 => 'Mañana · $time',
      _ => '$date · $time',
    };
  }
}
