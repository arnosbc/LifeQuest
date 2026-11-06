import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';
import 'package:proyecto_movil/features/reminders/domain/repositories/reminders_repository.dart';

/// Reprograma los avisos del teléfono con lo que dice el servidor.
class SyncReminders implements UseCase<Unit, NoParams> {
  SyncReminders(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final RemindersRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final plan = await _repository.getPlan();
    return plan.match(
      (failure) async => Left(failure),
      (plan) => _repository.replaceAll(build(plan, _clock())),
    );
  }

  /// Avisos del plan. Lo que cae en la ventana de silencio se corre a su
  /// final (no son avisos críticos, CLAUDE.md §7); lo ya pasado se omite.
  static List<LocalReminder> build(ReminderPlan plan, DateTime now) {
    final out = <LocalReminder>[];
    for (final task in plan.tasks) {
      final at = _afterSilence(
        task.startsAt.subtract(Duration(minutes: task.minutesBefore)),
        plan,
      );
      if (!at.isAfter(now)) continue;
      out.add(
        LocalReminder(
          id: out.length + 1,
          title: task.title,
          body: task.minutesBefore == 0
              ? 'Es la hora. Tú puedes con esto.'
              : 'Empieza a las ${_hhmm(task.startsAt)}. Prepárate con calma.',
          at: at,
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
        out.add(
          LocalReminder(
            id: out.length + 1,
            title: habit.name,
            body: 'Tu hábito de hoy te está esperando.',
            at: at,
            weekly: true,
          ),
        );
      }
    }
    return out;
  }

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
