import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_calendar.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_row.dart';

class GoodHabitsView extends StatelessWidget {
  const GoodHabitsView({
    super.key,
    required this.completed,
    required this.onToggle,
  });

  /// Índices de hábitos completados; el estado vive en la página para que
  /// sobreviva al cambio de pestaña.
  final Set<int> completed;
  final ValueChanged<int> onToggle;

  static const _habits = [
    ('Leer', Icons.menu_book_rounded, '5/7'),
    ('Hacer ejercicio', Icons.fitness_center, '6/7'),
    ('Estudiar', Icons.school_outlined, '7/7'),
    ('Beber agua', Icons.water_drop_outlined, '4/7'),
    ('Dormir temprano', Icons.nightlight_round, '4/7'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const LifeQuestSurface(
        color: Color(0xFFEBF9EF),
        child: Row(
          children: [
            Text('🔥', style: TextStyle(fontSize: 24)),
            SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Racha actual 12 días',
                    style: TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Cada hábito positivo suma XP y monedas. Cada día superado refuerza tu progreso.',
                    style: TextStyle(
                      color: LifeQuestColors.muted,
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
      const LifeQuestSectionHeading('BUENOS HÁBITOS'),
      const SizedBox(height: 6),
      for (var i = 0; i < _habits.length; i++)
        HabitRow(
          name: _habits[i].$1,
          icon: _habits[i].$2,
          progress: _habits[i].$3,
          complete: completed.contains(i),
          onToggle: () => onToggle(i),
        ),
      const SizedBox(height: 9),
      const LifeQuestSectionHeading('RESUMEN SEMANAL'),
      const SizedBox(height: 6),
      const Row(
        children: [
          Expanded(
            child: LifeQuestStat(value: '1,250 XP', label: 'XP obtenida'),
          ),
          SizedBox(width: 7),
          Expanded(
            child: LifeQuestStat(
              value: '24 / 35',
              label: 'Hábitos completados',
            ),
          ),
        ],
      ),
      const SizedBox(height: 13),
      const HabitCalendar(),
    ],
  );
}
