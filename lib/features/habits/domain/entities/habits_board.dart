import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';

/// Skill a la que se puede vincular un hábito.
class HabitSkill extends Equatable {
  const HabitSkill({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Todo lo que muestra la pantalla Hábitos, en una sola carga.
class HabitsBoard extends Equatable {
  const HabitsBoard({
    required this.habits,
    this.weekXp = 0,
    this.weekDone = 0,
    this.weekScheduled = 0,
    this.badFreeDays = 7,
    this.monthDays = const [],
    this.monthHeat = const {},
    this.monthDone = 0,
    this.yearDone = 0,
    this.skills = const [],
  });

  final List<Habit> habits;

  /// XP ganada con hábitos en los últimos 7 días.
  final int weekXp;

  /// Hábitos buenos cumplidos / que tocaban en los últimos 7 días.
  final int weekDone;
  final int weekScheduled;

  /// Días de los últimos 7 sin ningún evento de hábito malo.
  final int badFreeDays;

  /// Días del mes en curso con al menos un hábito bueno cumplido.
  final List<int> monthDays;

  /// Registros de hábitos buenos por día del mes (mapa de calor, 042).
  final Map<int, int> monthHeat;

  /// Registros de hábitos buenos del mes y del año (042).
  final int monthDone;
  final int yearDone;
  final List<HabitSkill> skills;

  List<Habit> get good =>
      habits.where((h) => h.type == HabitType.good).toList();

  /// Camino de hoy: hábitos buenos que tocan hoy, prioridad alta primero y,
  /// dentro de cada prioridad, en el orden en que llegan.
  List<Habit> get path {
    final today = [
      for (final h in good)
        if (h.scheduledToday) h,
    ];
    // List.sort no es estable: el índice desempata.
    final order = {for (final (i, h) in today.indexed) h.id: i};
    return today..sort(
      (a, b) => a.priority.index != b.priority.index
          ? a.priority.index - b.priority.index
          : order[a.id]! - order[b.id]!,
    );
  }

  /// Único hábito del Camino que se puede cumplir: el primero sin hacer.
  /// Los de después quedan bloqueados hasta cumplirlo.
  Habit? get currentOnPath {
    for (final h in path) {
      if (!h.doneToday) return h;
    }
    return null;
  }

  /// Hábito bueno cuya racha se reinició (0 hoy, pero tuvo récord), el de
  /// mayor récord: para animar a retomarla. Null si ninguna se rompió o si
  /// ya se cumplió hoy.
  Habit? get brokenStreak {
    Habit? best;
    for (final h in good) {
      if (h.currentStreak == 0 &&
          h.bestStreak > 0 &&
          !h.doneToday &&
          (best == null || h.bestStreak > best.bestStreak)) {
        best = h;
      }
    }
    return best;
  }

  List<Habit> get bad => habits.where((h) => h.type == HabitType.bad).toList();

  @override
  List<Object?> get props => [
    habits,
    weekXp,
    weekDone,
    weekScheduled,
    badFreeDays,
    monthDays,
    monthHeat,
    monthDone,
    yearDone,
    skills,
  ];
}
