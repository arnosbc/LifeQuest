import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/bad_habits_view.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/good_habits_view.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_tab_button.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final Set<int> _completed = {0, 1};
  bool _showBadHabits = false;

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Hábitos',
    subtitle: 'La constancia también es una aventura.',
    children: [
      Row(
        children: [
          Expanded(
            child: HabitTabButton(
              label: 'Buenos hábitos',
              selected: !_showBadHabits,
              onTap: () => setState(() => _showBadHabits = false),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: HabitTabButton(
              label: 'Malos hábitos',
              selected: _showBadHabits,
              onTap: () => setState(() => _showBadHabits = true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 11),
      if (_showBadHabits)
        const BadHabitsView()
      else
        GoodHabitsView(
          completed: _completed,
          onToggle: (index) => setState(
            () => _completed.contains(index)
                ? _completed.remove(index)
                : _completed.add(index),
          ),
        ),
    ],
  );
}
