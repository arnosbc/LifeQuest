import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class HabitStrip extends StatefulWidget {
  const HabitStrip({super.key});

  @override
  State<HabitStrip> createState() => _HabitStripState();
}

class _HabitStripState extends State<HabitStrip> {
  final Set<int> _completedHabits = {0, 1};

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(7),
    child: Row(
      children: [
        _habitChip(0, 'Leer', Icons.menu_book_outlined),
        _habitChip(1, 'Ejercicio', Icons.fitness_center),
        _habitChip(2, 'Agua', Icons.water_drop_outlined),
      ],
    ),
  );

  Widget _habitChip(int index, String label, IconData icon) => Expanded(
    child: InkWell(
      onTap: () => setState(
        () => _completedHabits.contains(index)
            ? _completedHabits.remove(index)
            : _completedHabits.add(index),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: _completedHabits.contains(index)
              ? LifeQuestColors.softGreen
              : Colors.white,
          border: Border.all(color: LifeQuestColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              _completedHabits.contains(index) ? Icons.check_circle : icon,
              color: _completedHabits.contains(index)
                  ? LifeQuestColors.green
                  : LifeQuestColors.muted,
              size: 17,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
