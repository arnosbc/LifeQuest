import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
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
  });

  final HabitsBoard board;
  final DateTime now;
  final String? busyHabitId;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onComplete;

  @override
  Widget build(BuildContext context) {
    final habits = board.good;
    final streak = habits.fold(
      0,
      (best, h) => h.currentStreak > best ? h.currentStreak : best,
    );
    return Column(
      children: [
        LifeQuestSurface(
          color: context.lq.softGreen,
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak == 0
                          ? 'Empieza tu racha hoy'
                          : 'Racha actual $streak ${streak == 1 ? 'día' : 'días'}',
                      style: TextStyle(
                        color: context.lq.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cada hábito positivo suma XP y monedas. Cada día superado refuerza tu progreso.',
                      style: TextStyle(
                        color: context.lq.muted,
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        LifeQuestSectionHeading(
          'BUENOS HÁBITOS',
          action: '${habits.length} activos',
        ),
        const SizedBox(height: 6),
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
