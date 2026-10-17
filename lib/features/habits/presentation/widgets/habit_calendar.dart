import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class HabitCalendar extends StatelessWidget {
  const HabitCalendar({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
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
    ],
  );

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
}
