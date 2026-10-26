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
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESIÓN DEEP WORKING',
            style: TextStyle(
              color: LifeQuestColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
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
            'MOCHILA · ${session.tasks.length} misiones · $done completadas',
            style: const TextStyle(
              color: LifeQuestColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Toca una misión para concentrarte en ella este ciclo.',
            style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
          ),
          for (final task in session.tasks) _task(task),
        ],
      ),
    );
  }

  Widget _task(DungeonTask task) {
    final current = task.id == currentTaskId;
    return Container(
      margin: const EdgeInsets.only(top: 7),
      decoration: BoxDecoration(
        color: current ? LifeQuestColors.softGreen : LifeQuestColors.background,
        border: Border.all(
          color: current ? LifeQuestColors.deepGreen : LifeQuestColors.line,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      // Material propio: el toque del ListTile se ve sobre el fondo.
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          selected: current,
          child: ListTile(
            dense: true,
            onTap: task.done ? null : () => onSelect(task.id),
            title: Text(
              task.title,
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${current ? 'En foco · ' : ''}${task.cycles} ${task.cycles == 1 ? 'ciclo' : 'ciclos'}',
              style: const TextStyle(color: LifeQuestColors.muted, fontSize: 9),
            ),
            trailing: task.done
                ? const Icon(Icons.check_circle, color: LifeQuestColors.green)
                : IconButton(
                    tooltip: 'Completar «${task.title}»',
                    onPressed: onComplete == null
                        ? null
                        : () => onComplete!(task.id),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: LifeQuestColors.deepGreen,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
