import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_calendar.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_row.dart';

class GoodHabitsView extends StatelessWidget {
  const GoodHabitsView({
    super.key,
    required this.board,
    required this.now,
    required this.busyHabitId,
    required this.onComplete,
    this.menuFor,
  });

  final HabitsBoard board;
  final DateTime now;
  final String? busyHabitId;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onComplete;

  /// Menú «⋯» de cada hábito.
  final Widget Function(Habit habit)? menuFor;

  @override
  Widget build(BuildContext context) {
    final habits = board.good;
    return Column(
      children: [
        if (habits.isEmpty)
          LifeQuestSurface(
            child: Text(
              'Aún no tienes hábitos buenos. Crea uno pequeño para empezar.',
              style: TextStyle(color: context.lq.muted, fontSize: 11),
            ),
          ),
        for (final habit in habits)
          HabitRow(
            habit: habit,
            busy: busyHabitId == habit.id,
            onComplete: onComplete == null ? null : () => onComplete!(habit.id),
            menu: menuFor?.call(habit),
          ),
        const SizedBox(height: 9),
        const LifeQuestSectionHeading('RESUMEN SEMANAL'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(
                value: '${board.weekXp} XP',
                label: 'XP obtenida',
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(
                value: '${board.weekDone} / ${board.weekScheduled}',
                label: 'Hábitos completados',
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        HabitCalendar(month: now, activeDays: board.monthDays.toSet()),
      ],
    );
  }
}
