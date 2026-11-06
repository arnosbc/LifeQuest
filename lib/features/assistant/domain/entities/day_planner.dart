import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';

/// Reglas del asistente (docs/plan-rework.md, fase 3). Deterministas: la IA
/// no decide horarios.
abstract final class DayPlanner {
  // shortcut: jornada fija de 8:00 a 22:00; pasarla a Ajustes si alguien
  // trabaja de noche.
  static const dayStartHour = 8;
  static const dayEndHour = 22;

  /// Llena los huecos libres de hoy con lo que no tiene hora, en orden:
  /// vencidas → prioridad → fecha límite más próxima.
  static DayPlan planDay(
    List<PlanTask> tasks,
    DateTime now, {
    List<Busy> events = const [],
  }) {
    final pending = tasks.where((t) => t.scheduledAt == null).toList();
    return _fill(PlanMode.planDay, pending, tasks, now, events, days: 1);
  }

  /// Lo vencido o con bloque pasado sin hacer va al siguiente hueco de hoy
  /// o de mañana.
  static DayPlan replan(
    List<PlanTask> tasks,
    DateTime now, {
    List<Busy> events = const [],
  }) {
    bool late(PlanTask t) => switch (t.scheduledAt) {
      final at? => !at.add(Duration(minutes: t.length)).isAfter(now),
      null => t.due != null && t.due!.isBefore(now),
    };
    final pending = tasks.where(late).toList();
    return _fill(PlanMode.replan, pending, tasks, now, events, days: 2);
  }

  /// [count] fechas repartidas de forma uniforme entre mañana y [deadline]
  /// (al final del día). Sin fecha límite, una por día desde mañana.
  static List<DateTime> spreadDates(
    int count,
    DateTime now, {
    DateTime? deadline,
  }) {
    if (count <= 0) return const [];
    final first = DateTime(now.year, now.month, now.day + 1);
    final last = deadline == null
        ? DateTime(first.year, first.month, first.day + count - 1)
        : DateTime(deadline.year, deadline.month, deadline.day);
    final span = last.isAfter(first) ? _days(first, last) : 0;
    return [
      for (var i = 0; i < count; i++)
        DateTime(
          first.year,
          first.month,
          first.day + (count == 1 ? span : (span * i / (count - 1)).round()),
          23,
          59,
        ),
    ];
  }

  static DayPlan _fill(
    PlanMode mode,
    List<PlanTask> pending,
    List<PlanTask> all,
    DateTime now,
    List<Busy> events, {
    required int days,
  }) {
    final moving = {for (final t in pending) t.id};
    // Lo que ya tiene hora y no se mueve ocupa su tramo.
    final busy = [
      ...events,
      for (final t in all)
        if (t.scheduledAt case final at? when !moving.contains(t.id))
          Busy(at, at.add(Duration(minutes: t.length))),
    ];
    final ordered = [...pending]..sort((a, b) => _compare(a, b, now));
    final blocks = <ProposedBlock>[];
    final left = <PlanTask>[];
    for (final task in ordered) {
      final start = _firstGap(task.length, busy, now, days);
      if (start == null) {
        left.add(task);
        continue;
      }
      final block = ProposedBlock(
        taskId: task.id,
        title: task.title,
        start: start,
        minutes: task.length,
      );
      blocks.add(block);
      busy.add(Busy(block.start, block.end));
    }
    return DayPlan(mode: mode, blocks: blocks, left: left);
  }

  static int _compare(PlanTask a, PlanTask b, DateTime now) {
    final overdueA = a.due != null && a.due!.isBefore(now);
    final overdueB = b.due != null && b.due!.isBefore(now);
    if (overdueA != overdueB) return overdueA ? -1 : 1;
    if (a.priority != b.priority) return b.priority - a.priority;
    if (a.due != b.due) {
      if (a.due == null) return 1;
      if (b.due == null) return -1;
      return a.due!.compareTo(b.due!);
    }
    return 0;
  }

  /// Primer inicio (múltiplo de 15 min) donde caben [minutes] sin chocar.
  static DateTime? _firstGap(
    int minutes,
    List<Busy> busy,
    DateTime now,
    int days,
  ) {
    for (var d = 0; d < days; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      final open = DateTime(day.year, day.month, day.day, dayStartHour);
      final close = DateTime(day.year, day.month, day.day, dayEndHour);
      var start = _roundUp(now.isAfter(open) ? now : open);
      while (!start.add(Duration(minutes: minutes)).isAfter(close)) {
        final end = start.add(Duration(minutes: minutes));
        final clash = busy.where((b) => b.overlaps(start, end)).toList();
        if (clash.isEmpty) return start;
        // Salta al final del choque más tardío.
        start = _roundUp(
          clash.map((b) => b.end).reduce((a, b) => a.isAfter(b) ? a : b),
        );
      }
    }
    return null;
  }

  static DateTime _roundUp(DateTime t) {
    final base = DateTime(t.year, t.month, t.day, t.hour);
    final extra = t.difference(base);
    final steps = (extra.inSeconds / (15 * 60)).ceil();
    return base.add(Duration(minutes: 15 * steps));
  }

  static int _days(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}
