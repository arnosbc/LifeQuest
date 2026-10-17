import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';
import 'widgets/bad_habits_view.dart';
import 'widgets/good_habits_view.dart';
import 'widgets/habit_tab_button.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
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
