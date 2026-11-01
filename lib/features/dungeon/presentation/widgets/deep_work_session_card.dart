import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/cycle_duration_card.dart';

/// La sesión en curso: duración, avance y la mochila de misiones.
class DeepWorkSessionCard extends StatelessWidget {
  const DeepWorkSessionCard({
    super.key,
    required this.session,
    required this.currentTaskId,
    required this.onSelect,
    required this.onComplete,
  });

  final DungeonSession session;
  final String? currentTaskId;
  final ValueChanged<String> onSelect;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onComplete;

  @override
  Widget build(BuildContext context) {
    final done = session.tasks.where((t) => t.done).length;
    return LifeQuestSurface(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sesión',
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LifeQuestStat(
                  value: CycleDurationCard.hours(session.totalMinutes),
                  label: 'Duración total',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: LifeQuestStat(
                  value: CycleDurationCard.hours(
                    session.cyclesDone * session.cycleMinutes,
                  ),
                  label: 'Completado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            'Tareas · $done de ${session.tasks.length} hechas',
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Toca una tarea para concentrarte en ella este ciclo.',
            style: TextStyle(color: context.lq.muted, fontSize: 13),
          ),
          for (final task in session.tasks) _task(context, task),
        ],
      ),
    );
  }

  Widget _task(BuildContext context, DungeonTask task) {
    final current = task.id == currentTaskId;
    // Tocar la fila la pone en foco; el check la completa.
    return Semantics(
      selected: current,
      child: InkWell(
        onTap: task.done ? null : () => onSelect(task.id),
        child: SheetRow(
          current: current && !task.done,
          done: task.done,
          leading: SheetCheck(
            done: task.done,
            label: 'Completar «${task.title}»',
            onTap: task.done || onComplete == null
                ? null
                : () => onComplete!(task.id),
          ),
          title: task.title,
          subtitle:
              '${current ? 'En foco · ' : ''}${task.cycles} '
              '${task.cycles == 1 ? 'ciclo' : 'ciclos'}',
        ),
      ),
    );
  }
}
