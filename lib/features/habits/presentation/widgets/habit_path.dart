import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';

const _priorityLabel = {
  HabitPriority.high: 'Alta',
  HabitPriority.medium: 'Media',
  HabitPriority.low: 'Baja',
};

/// Camino de niveles: nodos en zigzag; hecho (dorado), actual (con anillo),
/// bloqueado (gris con candado) y un trofeo al final.
class HabitPath extends StatelessWidget {
  const HabitPath({
    super.key,
    required this.path,
    required this.current,
    required this.busyHabitId,
    required this.onComplete,
  });

  /// [HabitsBoard.path] y [HabitsBoard.currentOnPath].
  final List<Habit> path;
  final Habit? current;
  final String? busyHabitId;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onComplete;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();
    final at = current == null ? -1 : path.indexOf(current!);
    return QuestPath(
      current: at < 0 ? null : at,
      celebrate: current == null,
      nodes: [
        for (final habit in path) _node(context, habit),
        _Trophy(won: current == null),
      ],
    );
  }

  Widget _node(BuildContext context, Habit habit) {
    final state = habit.doneToday
        ? QuestPathState.done
        : habit == current
        ? QuestPathState.current
        : QuestPathState.locked;
    final status = switch (state) {
      QuestPathState.done => 'cumplido hoy',
      QuestPathState.current => 'toca ahora, toca para cumplirlo',
      _ => 'bloqueado',
    };
    return QuestPathNode(
      state: state,
      label: habit.name,
      sublabel: 'Prioridad ${_priorityLabel[habit.priority]!.toLowerCase()}',
      bubble: state == QuestPathState.current ? 'CUMPLIR' : null,
      semanticsLabel:
          '${habit.name}, prioridad ${_priorityLabel[habit.priority]}, $status',
      busy: busyHabitId == habit.id,
      onTap: switch (state) {
        QuestPathState.done => null,
        QuestPathState.current =>
          onComplete == null ? null : () => onComplete!(habit.id),
        _ => () => showLifeQuestMessage(
          context,
          'Primero cumple «${current!.name}».',
        ),
      },
    );
  }
}

/// Meta del Camino: se ilumina al cumplir todos los hábitos de hoy.
class _Trophy extends StatelessWidget {
  const _Trophy({required this.won});

  final bool won;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      label: won ? 'Camino de hoy completo' : 'Meta del camino de hoy',
      excludeSemantics: true,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: won ? q.mustardTint : q.card,
          shape: BoxShape.circle,
          border: Border.all(color: won ? q.mustard : q.border, width: 3),
        ),
        child: Center(
          child: QIcon(
            QIcons.trophy,
            color: won ? q.mustardInk : q.text3,
            size: 30,
          ),
        ),
      ),
    );
  }
}
