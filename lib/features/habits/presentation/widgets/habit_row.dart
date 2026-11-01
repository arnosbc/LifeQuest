import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';

/// Hábito bueno: la misma fila de la hoja que Hoy, con su semana debajo.
class HabitRow extends StatelessWidget {
  const HabitRow({
    super.key,
    required this.habit,
    required this.busy,
    required this.onComplete,
    this.menu,
  });

  final Habit habit;
  final bool busy;

  /// Null mientras otra acción está en curso.
  final VoidCallback? onComplete;

  /// Menú «⋯» (renombrar, borrar).
  final Widget? menu;

  static const _dayLetters = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

  String get _frequency => habit.specificDays.isEmpty
      ? 'Diario'
      : habit.specificDays.map((d) => _dayLetters[d]).join(' ');

  @override
  Widget build(BuildContext context) {
    final doneDays = habit.week.where((d) => d).length;
    return SheetRow(
      leading: SheetCheck(
        done: habit.doneToday,
        busy: busy,
        label: habit.doneToday
            ? '«${habit.name}» cumplido hoy'
            : habit.scheduledToday
            ? 'Cumplir «${habit.name}» hoy'
            : '«${habit.name}» no toca hoy',
        onTap: habit.doneToday || !habit.scheduledToday ? null : onComplete,
      ),
      title: habit.name,
      done: habit.doneToday,
      muted: !habit.scheduledToday,
      subtitle: [
        if (!habit.scheduledToday) 'No toca hoy',
        '$doneDays de 7 días',
        _frequency,
        if (habit.currentStreak > 0) 'racha ${habit.currentStreak}',
      ].join(' · '),
      trailing: menu,
    );
  }
}
