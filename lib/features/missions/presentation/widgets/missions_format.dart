import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';

/// Textos de fechas, urgencia y origen de las misiones, en español.
abstract final class MissionsFormat {
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String priority(MissionPriority priority) => switch (priority) {
    MissionPriority.high => 'Alta',
    MissionPriority.medium => 'Media',
    MissionPriority.low => 'Baja',
  };

  /// Piel del bucket del Daily Highlight (RF-089); el estado real no cambia.
  static String bucket(MissionBucket bucket) => switch (bucket) {
    MissionBucket.urgent => '¡Hazlo ahora!',
    MissionBucket.high => 'Alta',
    MissionBucket.medium => 'Media',
    MissionBucket.low => 'Baja',
    MissionBucket.pending => 'Delegada',
  };

  /// Meta > Proyecto > Skill; sin vínculo, "Misión libre".
  static String origin(Mission mission) =>
      mission.goalTitle ??
      mission.projectTitle ??
      mission.skillName ??
      'Misión libre';

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

  /// Vista previa de la regla del servidor (`_task_xp`, migración 005):
  /// 10 base, +10 título de 5 palabras o más, +10 alta / +5 media,
  /// +10 con Meta o +5 con Proyecto. El servidor decide el valor final.
  static int estimatedXp({
    required String title,
    required MissionPriority priority,
    required bool hasGoal,
    required bool hasProject,
  }) {
    final words = title.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return 10 +
        (words.length >= 5 ? 10 : 0) +
        switch (priority) {
          MissionPriority.high => 10,
          MissionPriority.medium => 5,
          MissionPriority.low => 0,
        } +
        (hasGoal ? 10 : (hasProject ? 5 : 0));
  }

  /// Monedas = 30 % de la XP.
  static int estimatedCoins(int xp) => (xp * .3).round();
}
