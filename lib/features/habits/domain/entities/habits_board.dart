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
  final List<HabitSkill> skills;

  List<Habit> get good =>
      habits.where((h) => h.type == HabitType.good).toList();

  List<Habit> get bad => habits.where((h) => h.type == HabitType.bad).toList();

  @override
  List<Object?> get props => [
    habits,
    weekXp,
    weekDone,
    weekScheduled,
    badFreeDays,
    monthDays,
    skills,
  ];
}
