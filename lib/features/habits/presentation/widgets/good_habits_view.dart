import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
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
        LifeQuestSectionHeading(
          'HÁBITOS BUENOS',
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
            menu: menuFor?.call(habit),
          ),
        const SizedBox(height: 16),
        // Habitos.dc.html: Estadísticas de crecimiento (042).
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            child: Text(
              'Estadísticas de crecimiento',
              style: QText.title3(context.q.text).copyWith(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Growth('Esta semana', board.weekDone)),
            const SizedBox(width: 8),
            Expanded(child: _Growth('Este mes', board.monthDone)),
            const SizedBox(width: 8),
            Expanded(
              child: _Growth('Este año', board.yearDone, highlight: true),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '+${board.weekXp} XP con hábitos en los últimos 7 días',
            style: QText.body(context.q.text2).copyWith(fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        HabitCalendar(month: now, heat: board.monthHeat),
      ],
    );
  }
}

/// Una cifra de «Estadísticas de crecimiento»: hábitos buenos cumplidos.
class _Growth extends StatelessWidget {
  const _Growth(this.label, this.value, {this.highlight = false});

  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      label: '$label: $value hábitos cumplidos',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(QSpace.m),
        decoration: BoxDecoration(
          color: highlight ? q.tint : q.card,
          borderRadius: BorderRadius.circular(QRadius.control),
          border: highlight ? null : Border.all(color: q.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: QText.body(
                highlight ? q.ink : q.text2,
              ).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: QText.number(highlight ? q.ink : q.text, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
