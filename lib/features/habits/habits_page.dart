import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final Set<int> _completed = {0, 1};
  bool _showBadHabits = false;

  static const _habits = [
    ('Leer', Icons.menu_book_rounded, '5/7'),
    ('Hacer ejercicio', Icons.fitness_center, '6/7'),
    ('Estudiar', Icons.school_outlined, '7/7'),
    ('Beber agua', Icons.water_drop_outlined, '4/7'),
    ('Dormir temprano', Icons.nightlight_round, '4/7'),
  ];

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Hábitos',
    subtitle: 'La constancia también es una aventura.',
    children: [
      Row(
        children: [
          Expanded(
            child: _tab(
              'Buenos hábitos',
              selected: !_showBadHabits,
              onTap: () => setState(() => _showBadHabits = false),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _tab(
              'Malos hábitos',
              selected: _showBadHabits,
              onTap: () => setState(() => _showBadHabits = true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 11),
      if (!_showBadHabits) ..._goodHabitContent() else ..._badHabitContent(),
    ],
  );

  List<Widget> _goodHabitContent() => [
    LifeQuestSurface(
      color: const Color(0xFFEBF9EF),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 9),
          const Expanded(
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
    ...List.generate(_habits.length, _habitRow),
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
          child: LifeQuestStat(value: '24 / 35', label: 'Hábitos completados'),
        ),
      ],
    ),
    const SizedBox(height: 13),
    const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'CALENDARIO',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Mayo 2024',
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
    const SizedBox(height: 6),
    LifeQuestSurface(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('D'),
              Text('L'),
              Text('M'),
              Text('M'),
              Text('J'),
              Text('V'),
              Text('S'),
            ],
          ),
          const SizedBox(height: 7),
          for (var week = 0; week < 4; week++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var day = 1; day <= 7; day++)
                    _calendarDay(week * 7 + day),
                ],
              ),
            ),
        ],
      ),
    ),
  ];

  List<Widget> _badHabitContent() => [
    LifeQuestSurface(
      color: const Color(0xFFFFF8F7),
      child: Row(
        children: [
          const Icon(Icons.favorite_border, color: Color(0xFFE67777), size: 23),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Reconocer tus patrones te ayuda a cambiarlos. Registra cada día y sigue avanzando.',
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
    const LifeQuestSectionHeading(
      'HÁBITOS QUE QUIERO EVITAR',
      action: '3 activos',
    ),
    const SizedBox(height: 7),
    _badHabit('Pantallas antes de dormir'),
    _badHabit('Café después de las 16:00'),
    _badHabit('Compras impulsivas'),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () =>
                showLifeQuestMessage(context, 'Recaída registrada.'),
            child: const Text('Registrar recaída'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: FilledButton(
            onPressed: () => showLifeQuestMessage(context, '¡Día superado!'),
            style: FilledButton.styleFrom(
              backgroundColor: LifeQuestColors.green,
            ),
            child: const Text('Día superado'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 15),
    const LifeQuestSectionHeading('RESUMEN SEMANAL'),
    const SizedBox(height: 6),
    const Row(
      children: [
        Expanded(
          child: LifeQuestStat(value: '4 días', label: 'Sin recaídas'),
        ),
        SizedBox(width: 7),
        Expanded(
          child: LifeQuestStat(value: '1,250 XP', label: 'XP obtenida'),
        ),
      ],
    ),
  ];

  Widget _tab(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? LifeQuestColors.green : Colors.white,
        border: Border.all(
          color: selected ? LifeQuestColors.green : LifeQuestColors.line,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : LifeQuestColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _habitRow(int index) {
    final habit = _habits[index];
    final progressDays = int.parse(habit.$3[0]);
    final complete = _completed.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LifeQuestSurface(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            LifeQuestIconTile(habit.$2, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.$1,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      7,
                      (day) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 3, top: 4),
                        decoration: BoxDecoration(
                          color: day < progressDays
                              ? LifeQuestColors.green
                              : LifeQuestColors.line,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${habit.$3}\nDIARIO',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: LifeQuestColors.muted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(
                () =>
                    complete ? _completed.remove(index) : _completed.add(index),
              ),
              icon: Icon(
                complete ? Icons.check_circle : Icons.circle_outlined,
                color: complete ? LifeQuestColors.green : LifeQuestColors.muted,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarDay(int day) {
    final active = [3, 6, 10, 15, 20, 25].contains(day);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? LifeQuestColors.green
            : day % 3 == 0
            ? LifeQuestColors.softGreen
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$day',
        style: TextStyle(
          color: active ? Colors.white : LifeQuestColors.ink,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _badHabit(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: Color(0xFFE67777),
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            '0/7',
            style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}
