import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Mapa de calor del mes: días con al menos un hábito bueno cumplido.
class HabitCalendar extends StatelessWidget {
  const HabitCalendar({
    super.key,
    required this.month,
    required this.activeDays,
  });

  /// Cualquier fecha del mes a mostrar (hoy se resalta con borde).
  final DateTime month;
  final Set<int> activeDays;

  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Columna del día 1: 0 = domingo (weekday 7 → 0).
    final offset = DateTime(month.year, month.month).weekday % 7;
    final weeks = ((offset + daysInMonth) / 7).ceil();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CALENDARIO',
              style: TextStyle(
                color: context.lq.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_months[month.month - 1]} ${month.year}',
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LifeQuestSurface(
          padding: const EdgeInsets.all(10),
          child: Semantics(
            label: '${activeDays.length} días con hábitos cumplidos este mes',
            excludeSemantics: true,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final d in const ['D', 'L', 'M', 'X', 'J', 'V', 'S'])
                      SizedBox(width: 22, child: Center(child: Text(d))),
                  ],
                ),
                const SizedBox(height: 7),
                for (var week = 0; week < weeks; week++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (var col = 0; col < 7; col++)
                          _day(
                            context,
                            week * 7 + col - offset + 1,
                            daysInMonth,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _day(BuildContext context, int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(width: 22);
    final active = activeDays.contains(day);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? context.lq.green : Colors.transparent,
        border: day == month.day
            ? Border.all(color: context.lq.deepGreen, width: 1.5)
            : null,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$day',
        style: TextStyle(
          color: active ? context.lq.onDeepGreen : context.lq.ink,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
