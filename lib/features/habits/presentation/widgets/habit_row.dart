import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';

/// Hábito bueno: progreso de la semana y botón para cumplirlo hoy.
class HabitRow extends StatelessWidget {
  const HabitRow({
    super.key,
    required this.habit,
    required this.busy,
    required this.onComplete,
  });

  final Habit habit;
  final bool busy;

  /// Null mientras otra acción está en curso.
  final VoidCallback? onComplete;

  static const _dayLetters = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

  String get _frequency => habit.specificDays.isEmpty
      ? 'DIARIO'
      : habit.specificDays.map((d) => _dayLetters[d]).join(' ');

  @override
  Widget build(BuildContext context) {
    final doneDays = habit.week.where((d) => d).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LifeQuestSurface(
        padding: const EdgeInsets.fromLTRB(9, 4, 4, 4),
        child: Row(
          children: [
            const LifeQuestIconTile(Icons.eco_outlined, size: 28),
            const SizedBox(width: 8),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Semantics(
                    label: '$doneDays de los últimos 7 días',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        for (final done in habit.week)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 3, top: 4),
                            decoration: BoxDecoration(
                              color: done ? context.lq.green : context.lq.line,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (habit.currentStreak > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 4),
                            child: Text(
                              '🔥 ${habit.currentStreak}',
                              style: TextStyle(
                                color: context.lq.muted,
                                fontSize: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$doneDays/7\n$_frequency',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: context.lq.muted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (busy)
              SizedBox(
                width: 48,
                height: 48,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.lq.deepGreen,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: habit.doneToday || !habit.scheduledToday
                    ? null
                    : onComplete,
                tooltip: habit.doneToday
                    ? '«${habit.name}» cumplido hoy'
                    : habit.scheduledToday
                    ? 'Cumplir «${habit.name}» hoy'
                    : '«${habit.name}» no toca hoy',
                icon: Icon(
                  habit.doneToday
                      ? Icons.check_circle
                      : habit.scheduledToday
                      ? Icons.circle_outlined
                      : Icons.bedtime_outlined,
                  color: habit.doneToday ? context.lq.green : context.lq.muted,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
