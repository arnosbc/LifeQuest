import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_format.dart';

/// Lista «Hoy» (plan S2): tareas que vencen hoy, vencidas o de prioridad alta.
/// El botón abre el Modo Foco con la tarea elegida (040).
class TodayList extends StatelessWidget {
  const TodayList({
    super.key,
    required this.tasks,
    required this.onFocus,
    this.busyTaskId,
    this.now,
  });

  final List<TodayTask> tasks;
  final ValueChanged<String> onFocus;
  final String? busyTaskId;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QuestlyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: q.line),
            _TaskRow(
              task: tasks[i],
              busy: tasks[i].id == busyTaskId,
              now: now ?? DateTime.now(),
              onFocus: () => onFocus(tasks[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.busy,
    required this.now,
    required this.onFocus,
  });

  final TodayTask task;
  final bool busy;
  final DateTime now;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final when = task.dueDate == null
        ? HomeFormat.priority(task.priority)
        : HomeFormat.due(task.dueDate, now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
      child: Row(
        children: [
          SizedBox.square(
            dimension: QSize.minTap + 4,
            child: Semantics(
              button: true,
              label: 'Empezar en Foco: ${task.title}',
              excludeSemantics: true,
              child: InkWell(
                onTap: busy ? null : onFocus,
                customBorder: const CircleBorder(),
                child: Center(
                  child: busy
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: q.ink,
                          ),
                        )
                      : Icon(
                          Icons.play_circle_outline_rounded,
                          size: 28,
                          color: q.ink,
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: QText.body(q.text).copyWith(fontSize: 15),
                ),
                Text(
                  task.priority == UrgencyLevel.high && task.dueDate != null
                      ? '▲ $when'
                      : when,
                  style: QText.body(
                    task.overdue ? q.coralInk : q.text2,
                  ).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: QSpace.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: q.tint,
              borderRadius: BorderRadius.circular(QRadius.chip),
            ),
            child: Text(
              '+${task.xpReward}',
              style: QText.number(q.ink, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
