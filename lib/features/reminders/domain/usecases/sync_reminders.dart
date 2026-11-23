import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';
import 'package:proyecto_movil/features/reminders/domain/repositories/reminders_repository.dart';

/// Reprograma los avisos del teléfono con lo que dice el servidor. El
/// parámetro es el fin de la sesión de Foco en curso (null si no hay):
/// hasta entonces lo no crítico espera (CLAUDE.md §7). Devuelve lo programado.
class SyncReminders implements UseCase<List<LocalReminder>, DateTime?> {
  SyncReminders(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final RemindersRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, List<LocalReminder>>> call(
    DateTime? quietUntil,
  ) async {
    final plan = await _repository.getPlan();
    return plan.match((failure) async => Left(failure), (plan) async {
      final reminders = build(plan, _clock(), quietUntil: quietUntil);
      return (await _repository.replaceAll(reminders)).map((_) => reminders);
    });
  }

  /// Avisos del plan para los próximos 7 días. Lo que cae en la ventana de
  /// silencio o en una sesión de Foco se corre a su final; lo ya pasado se
  /// omite. Con límite diario se quitan primero el resumen y el cierre del
  /// día: lo que el usuario pidió (tareas y hábitos con hora) y lo crítico
  /// (racha, proyecto) siempre llegan.
  static List<LocalReminder> build(
    ReminderPlan plan,
    DateTime now, {
    DateTime? quietUntil,
  }) {
    final quiet = quietUntil != null && quietUntil.isAfter(now)
        ? quietUntil
        : null;
    // Lo no crítico: silencio y luego Foco.
    DateTime calm(DateTime at) {
      final after = _afterSilence(at, plan);
      return quiet != null && after.isBefore(quiet) ? quiet : after;
    }

    final out = <LocalReminder>[];
    void add(LocalReminder r) {
      if (r.at.isAfter(now)) out.add(r);
    }

    for (final task in plan.tasks) {
      add(
        LocalReminder(
          id: 0,
          title: task.title,
          body: task.minutesBefore == 0
              ? 'Es la hora. Tú puedes con esto.'
              : 'Empieza a las ${_hhmm(task.startsAt)}. Prepárate con calma.',
          at: calm(
            task.startsAt.subtract(Duration(minutes: task.minutesBefore)),
          ),
          taskId: task.id,
        ),
      );
    }
    for (final habit in plan.habits) {
      for (final day in habit.days.toSet()) {
        // Dart: lunes = 1 … domingo = 7; el servidor: domingo = 0.
        final weekday = day == 0 ? DateTime.sunday : day;
        var at = _afterSilence(
          DateTime(
            now.year,
            now.month,
            now.day + (weekday - now.weekday) % 7,
            habit.minuteOfDay ~/ 60,
            habit.minuteOfDay % 60,
          ),
          plan,
        );
        if (!at.isAfter(now)) {
          at = DateTime(at.year, at.month, at.day + 7, at.hour, at.minute);
        }
        // Si cae en Foco sale al terminar, solo esta vez: al acabar la
        // sesión se vuelve a sincronizar y recupera su hora semanal.
        final held = quiet != null && at.isBefore(quiet);
        add(
          LocalReminder(
            id: 0,
            title: habit.name,
            body: 'Tu hábito de hoy te está esperando.',
            at: held ? quiet : at,
            habitId: habit.id,
            weekly: !held,
          ),
        );
      }
    }
    for (final project in plan.projects) {
      final d = project.day;
      add(
        LocalReminder(
          id: 0,
          title: '«${project.title}» necesita un empujón',
          body: 'A este ritmo no llega a su fecha. Dale un bloque hoy en Hoy.',
          at: _afterSilence(
            DateTime(d.year, d.month, d.day, _projectHour),
            plan,
          ),
          projectId: project.id,
        ),
      );
    }
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 7; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final o =
          plan.days.where((d) => _sameDay(d.day, day)).firstOrNull ??
          DayOutlook(day: day);
      if (o.tasks + o.habits > 0) {
        add(
          LocalReminder(
            id: 0,
            title: 'Tu día',
            body:
                '${_listOf(o)} te '
                '${_count(o.tasks + o.habits, 'espera', 'esperan')}. '
                'Empieza por lo más fácil.',
            at: calm(_at(day, _summaryHour)),
            kind: 'today',
          ),
        );
      }
      if (o.streakHabits > 0) {
        final at = _streakAt(day, plan);
        if (at != null) {
          add(
            LocalReminder(
              id: 0,
              title: i == 0 && o.bestStreak > 1
                  ? 'Tu racha de ${o.bestStreak} días te está esperando 🔥'
                  : 'Tus hábitos te esperan 🔥',
              body: i == 0
                  ? 'Te ${_count(o.streakHabits, 'falta', 'faltan')} '
                        '${o.streakHabits} ${_count(o.streakHabits, 'hábito', 'hábitos')} de hoy. '
                        'La versión mínima también cuenta.'
                  : 'Márcalos antes de dormir y tu racha sigue.',
              at: at,
              kind: 'streak',
            ),
          );
        }
      }
      if (plan.dayClose) {
        add(
          LocalReminder(
            id: 0,
            title: 'Cierra el día',
            body: 'Un minuto: decide qué pasa con lo pendiente.',
            at: calm(_at(day, _closeHour)),
            kind: 'close',
          ),
        );
      }
    }
    final kept = _applyLimit(out, plan.dailyLimit);
    return [for (final (i, r) in kept.indexed) r.withId(i + 1)];
  }

  static const _summaryHour = 8;
  static const _streakHour = 20;
  static const _closeHour = 21;
  static const _projectHour = 9;

  /// Racha en peligro: crítico. Si las 20:00 caen en silencio y no se permite
  /// saltarlo, sale una hora antes de que empiece (nunca antes del mediodía).
  static DateTime? _streakAt(DateTime day, ReminderPlan plan) {
    final at = _at(day, _streakHour);
    if (plan.criticalBypassSilence || _afterSilence(at, plan) == at) return at;
    final start = plan.silenceStart!;
    final earlier = DateTime(day.year, day.month, day.day, 0, start - 60);
    return earlier.hour >= 12 && _afterSilence(earlier, plan) == earlier
        ? earlier
        : null;
  }

  /// Con más avisos que el límite en un día, quita primero los resúmenes y
  /// luego los cierres de ese día.
  static List<LocalReminder> _applyLimit(List<LocalReminder> all, int? limit) {
    if (limit == null) return all;
    final dropped = <LocalReminder>{};
    final byDay = <DateTime, List<LocalReminder>>{};
    for (final r in all) {
      byDay
          .putIfAbsent(DateTime(r.at.year, r.at.month, r.at.day), () => [])
          .add(r);
    }
    for (final day in byDay.values) {
      var extra = day.length - limit;
      for (final kind in const ['today', 'close']) {
        for (final r in day.where((r) => r.kind == kind)) {
          if (extra <= 0) break;
          dropped.add(r);
          extra--;
        }
      }
    }
    return [
      for (final r in all)
        if (!dropped.contains(r)) r,
    ];
  }

  static DateTime _at(DateTime day, int hour) =>
      DateTime(day.year, day.month, day.day, hour);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _count(int n, String one, String many) => n == 1 ? one : many;

  static String _listOf(DayOutlook o) => [
    if (o.tasks > 0) '${o.tasks} ${_count(o.tasks, 'tarea', 'tareas')}',
    if (o.habits > 0) '${o.habits} ${_count(o.habits, 'hábito', 'hábitos')}',
  ].join(' y ');

  static DateTime _afterSilence(DateTime at, ReminderPlan plan) {
    final start = plan.silenceStart;
    final end = plan.silenceEnd;
    if (start == null || end == null || start == end) return at;
    final m = at.hour * 60 + at.minute;
    final wraps = start > end; // p. ej. 22:00–07:00
    final inside = wraps ? (m >= start || m < end) : (m >= start && m < end);
    if (!inside) return at;
    final nextDay = wraps && m >= start;
    return DateTime(
      at.year,
      at.month,
      at.day + (nextDay ? 1 : 0),
      end ~/ 60,
      end % 60,
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
