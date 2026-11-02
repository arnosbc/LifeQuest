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
    this.onOpenSteps,
  });

  final DungeonSession session;
  final String? currentTaskId;
  final ValueChanged<String> onSelect;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onComplete;

  /// Abre los pasos de la tarea (tarea guiada).
  final ValueChanged<String>? onOpenSteps;

  @override
  Widget build(BuildContext context) {
    final done = session.tasks.where((t) => t.done).length;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESIÓN DE FOCO',
            style: TextStyle(
              color: context.lq.muted,
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
            'TAREAS · ${session.tasks.length} · $done completadas',
            style: TextStyle(
              color: context.lq.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Toca una tarea para concentrarte en ella durante este bloque.',
            style: TextStyle(color: context.lq.muted, fontSize: 9),
          ),
          for (final task in session.tasks) _task(context, task),
        ],
      ),
    );
  }

  Widget _task(BuildContext context, DungeonTask task) {
    final current = task.id == currentTaskId;
    return Container(
      margin: const EdgeInsets.only(top: 7),
      decoration: BoxDecoration(
        color: current ? context.lq.softGreen : context.lq.background,
        border: Border.all(
          color: current ? context.lq.deepGreen : context.lq.line,
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
                color: context.lq.ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${current ? 'En foco · ' : ''}${task.cycles} '
              '${task.cycles == 1 ? 'bloque' : 'bloques'}',
              style: TextStyle(color: context.lq.muted, fontSize: 9),
            ),
            trailing: task.done
                ? Icon(Icons.check_circle, color: context.lq.green)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onOpenSteps != null)
                        IconButton(
                          tooltip: 'Pasos de «${task.title}»',
                          onPressed: () => onOpenSteps!(task.id),
                          icon: Icon(
                            Icons.format_list_numbered_rounded,
                            color: context.lq.deepGreen,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Completar «${task.title}»',
                        onPressed: onComplete == null
                            ? null
                            : () => onComplete!(task.id),
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: context.lq.deepGreen,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
