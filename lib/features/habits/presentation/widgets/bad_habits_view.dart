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
  });

  final HabitsBoard board;
  final String? busyHabitId;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onRegister;

  @override
  Widget build(BuildContext context) {
    final habits = board.bad;
    final todayEvents = habits.fold(0, (sum, h) => sum + h.todayCount);
    return Column(
      children: [
        const LifeQuestSurface(
          color: Color(0xFFFFF8F7),
          child: Row(
            children: [
              Icon(Icons.favorite_border, color: Color(0xFFE67777), size: 23),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Reconocer tus patrones te ayuda a cambiarlos. Registra cada vez que ocurra, sin culpa.',
                  style: TextStyle(
                    color: LifeQuestColors.muted,
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
          action: '${habits.length} activos',
        ),
        const SizedBox(height: 7),
        if (habits.isEmpty)
          const LifeQuestSurface(
            child: Text(
              'No tienes hábitos por evitar. Si quieres cambiar alguno, créalo aquí.',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 11),
            ),
          ),
        for (final habit in habits) _badHabit(habit),
        const SizedBox(height: 15),
        const LifeQuestSectionHeading('RESUMEN SEMANAL'),
        const SizedBox(height: 6),
        Row(
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
      ],
    );
  }

  Widget _badHabit(Habit habit) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      padding: const EdgeInsets.fromLTRB(9, 4, 4, 4),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: Color(0xFFE67777),
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
                  style: const TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Hoy: ${habit.todayCount} · −${habit.hpPenalty} de vida por registro',
                  style: const TextStyle(
                    color: LifeQuestColors.muted,
                    fontSize: 9,
                  ),
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
        ],
      ),
    ),
  );
}
