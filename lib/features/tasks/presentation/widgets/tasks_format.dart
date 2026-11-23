import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';

/// Textos de fechas, urgencia y origen de las tareas, en español.
abstract final class TasksFormat {
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

  static const _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  static String weekday(DateTime day) => _weekdays[day.weekday - 1];

  /// Texto de `repeat_rule` (032): "cada día", "cada lunes y miércoles"…
  static String? repeat(String? rule) {
    if (rule == null) return null;
    final [kind, ...rest] = rule.split(':');
    return switch (kind) {
      'daily' => 'Cada día',
      'weekdays' => 'De lunes a viernes',
      'weekly' =>
        'Cada ${rest.first.split(',').map((d) => _weekdays[(int.parse(d) + 6) % 7]).join(' y ')}',
      'monthly' => 'Cada mes, el día ${rest.first}',
      _ => null,
    };
  }

  /// "25 min de foco" o "25 de 60 min de foco" si hay duración estimada.
  static String? focus(Task task) {
    if (task.focusMinutes == 0) return null;
    final estimate = task.estimatedMinutes;
    return estimate == null
        ? '${task.focusMinutes} min de foco'
        : '${task.focusMinutes} de $estimate min de foco';
  }

  static String priority(TaskPriority priority) => switch (priority) {
    TaskPriority.high => 'Alta',
    TaskPriority.medium => 'Media',
    TaskPriority.low => 'Baja',
  };

  /// Piel del bucket del Daily Highlight (RF-089); el estado real no cambia.
  static String bucket(TaskBucket bucket) => switch (bucket) {
    TaskBucket.urgent => '¡Hazlo ahora!',
    TaskBucket.high => 'Alta',
    TaskBucket.medium => 'Media',
    TaskBucket.low => 'Baja',
    TaskBucket.pending => 'Delegada',
  };

  /// Meta > Proyecto > Skill; sin vínculo, "Tarea libre".
  static String origin(Task task) =>
      task.goalTitle ?? task.projectTitle ?? task.skillName ?? 'Tarea libre';

  /// "18:30", o vacío si no tiene fecha u hora (solo día).
  static String time(DateTime? due) => _hhmm(due) ?? '';

  /// "Hoy · 18:00", "Mañana · 09:30", "12 oct · 18:00" o, si ya pasó,
  /// "Pendiente desde el 12 oct" (sin culpa, solo el dato). Sin hora, solo
  /// el día: "Hoy", "Mañana", "12 oct".
  static String due(DateTime? due, DateTime now) {
    if (due == null) return 'Sin fecha límite';
    // En UTC para que un cambio de horario no altere la resta de días.
    final day = DateTime.utc(due.year, due.month, due.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final time = switch (_hhmm(due)) {
      final t? => ' · $t',
      null => '',
    };
    final date = '${due.day} ${_months[due.month - 1]}';
    if (due.isBefore(now)) {
      return day == today ? 'Era para hoy$time' : 'Pendiente desde el $date';
    }
    return switch (day.difference(today).inDays) {
      0 => 'Hoy$time',
      1 => 'Mañana$time',
      _ => '$date$time',
    };
  }

  /// "18:30"; null sin fecha o si es 23:59, la hora interna de una tarea
  /// que solo tiene día («vence hoy»).
  static String? _hhmm(DateTime? t) =>
      t == null || (t.hour == 23 && t.minute == 59)
      ? null
      : '${t.hour.toString().padLeft(2, '0')}:'
            '${t.minute.toString().padLeft(2, '0')}';

  /// Vista previa de la regla del servidor (`_task_xp`, migración 005):
  /// 10 base, +10 título de 5 palabras o más, +10 alta / +5 media,
  /// +10 con Meta o +5 con Proyecto. El servidor decide el valor final.
  static int estimatedXp({
    required String title,
    required TaskPriority priority,
    required bool hasGoal,
    required bool hasProject,
  }) {
    final words = title.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return 10 +
        (words.length >= 5 ? 10 : 0) +
        switch (priority) {
          TaskPriority.high => 10,
          TaskPriority.medium => 5,
          TaskPriority.low => 0,
        } +
        (hasGoal ? 10 : (hasProject ? 5 : 0));
  }

  /// Monedas = 30 % de la XP.
  static int estimatedCoins(int xp) => (xp * .3).round();
}
