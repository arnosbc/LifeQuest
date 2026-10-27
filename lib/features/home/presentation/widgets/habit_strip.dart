import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Hábitos buenos de hoy. Tocar uno pendiente lo registra; registrarlo da
/// XP y Monedas en el servidor, así que no se desmarca desde aquí.
class HabitStrip extends StatelessWidget {
  const HabitStrip({
    super.key,
    required this.habits,
    required this.onComplete,
    required this.onOpenHabits,
    this.busyHabitId,
  });

  /// shortcut: el Home muestra los 3 primeros; el resto está en Hábitos.
  static const maxVisible = 3;

  final List<TodayHabit> habits;
  final ValueChanged<String> onComplete;
  final VoidCallback onOpenHabits;
  final String? busyHabitId;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return LifeQuestSurface(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Hoy no tienes hábitos programados.',
                style: TextStyle(color: context.lq.muted, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: onOpenHabits,
              style: TextButton.styleFrom(
                foregroundColor: context.lq.deepGreen,
                minimumSize: const Size(48, 48),
              ),
              child: const Text('Crear hábito'),
            ),
          ],
        ),
      );
    }

    final visible = habits.take(maxVisible).toList();
    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _habitChip(context, visible[i])),
        ],
      ],
    );
  }

  Widget _habitChip(BuildContext context, TodayHabit habit) {
    final busy = habit.id == busyHabitId;
    return MergeSemantics(
      child: Semantics(
        checked: habit.done,
        child: Material(
          color: habit.done ? context.lq.softGreen : context.lq.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: habit.done ? context.lq.green : context.lq.line,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: InkWell(
            onTap: habit.done || busy ? null : () => onComplete(habit.id),
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: busy
                        ? Padding(
                            padding: EdgeInsets.all(3),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: context.lq.deepGreen,
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              habit.done
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              key: ValueKey(habit.done),
                              color: habit.done
                                  ? context.lq.deepGreen
                                  : context.lq.muted,
                              size: 24,
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.lq.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
