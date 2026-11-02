import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';

class BadHabitsView extends StatelessWidget {
  const BadHabitsView({
    super.key,
    required this.board,
    required this.busyHabitId,
    required this.onRegister,
    required this.onCreate,
    this.menuFor,
  });

  final HabitsBoard board;
  final String? busyHabitId;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onRegister;

  /// Null mientras otra acción está en curso.
  final VoidCallback? onCreate;

  /// Menú «⋯» de cada hábito.
  final Widget Function(Habit habit)? menuFor;

  @override
  Widget build(BuildContext context) {
    final habits = board.bad;
    final todayEvents = habits.fold(0, (sum, h) => sum + h.todayCount);
    return Column(
      children: [
        LifeQuestSurface(
          color: context.lq.warning.withValues(alpha: 0.06),
          child: Row(
            children: [
              Icon(Icons.favorite_border, color: context.lq.warning, size: 23),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Reconocer tus patrones te ayuda a cambiarlos. Registra cada vez que ocurra, sin culpa.',
                  style: TextStyle(
                    color: context.lq.muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        LifeQuestSectionHeading(
          'HÁBITOS QUE QUIERO EVITAR',
          action: '${habits.length}',
        ),
        const SizedBox(height: 7),
        if (habits.isEmpty)
          LifeQuestEmptyState(
            compact: true,
            illustration: LifeQuestIllustration.blank,
            title: 'No tienes hábitos por evitar',
            message: 'Si quieres cambiar alguno, anótalo y registra cada vez.',
            actionLabel: 'Crear hábito',
            onAction: onCreate,
          ),
        for (final habit in habits) _badHabit(context, habit),
        const SizedBox(height: 15),
        const LifeQuestSectionHeading('RESUMEN SEMANAL'),
        const SizedBox(height: 6),
        LifeQuestSurface(
          color: context.q.tint,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: LifeQuestStat(
                  value:
                      '${board.badFreeDays} ${board.badFreeDays == 1 ? 'día' : 'días'}',
                  label: 'Sin recaídas',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: LifeQuestStat(
                  value: '$todayEvents',
                  label: 'Registros de hoy',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badHabit(BuildContext context, Habit habit) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      padding: const EdgeInsets.fromLTRB(9, 4, 4, 4),
      child: Row(
        children: [
          Icon(
            Icons.remove_circle_outline,
            color: context.lq.warning,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.lq.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Hoy: ${habit.todayCount} · −${habit.hpPenalty} de vida por registro',
                  style: TextStyle(color: context.lq.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          if (busyHabitId == habit.id)
            const SizedBox(
              width: 48,
              height: 48,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: onRegister == null
                  ? null
                  : () => onRegister!(habit.id),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Semantics(
                label: 'Registrar «${habit.name}»',
                excludeSemantics: true,
                child: const Text('Registrar'),
              ),
            ),
          ?menuFor?.call(habit),
        ],
      ),
    ),
  );
}
