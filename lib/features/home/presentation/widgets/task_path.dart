import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Camino de hoy estilo Duolingo: lo ya hecho (dorado), la tarea que toca
/// (estrella con anillo), las siguientes y el cofre diario como meta.
/// Cualquier tarea se puede empezar en Foco (040); el orden solo guía.
class TaskPath extends StatelessWidget {
  const TaskPath({
    super.key,
    required this.dashboard,
    required this.claimingChest,
    required this.onFocus,
    required this.onClaimChest,
  });

  final HomeDashboard dashboard;
  final bool claimingChest;
  final ValueChanged<String> onFocus;
  final VoidCallback onClaimChest;

  @override
  Widget build(BuildContext context) {
    final d = dashboard;
    final current = d.priorityMission;
    final nodes = <Widget>[
      if (d.missionsDone > 0)
        QuestPathNode(
          state: QuestPathState.done,
          label: d.missionsDone == 1
              ? '1 tarea hecha hoy'
              : '${d.missionsDone} tareas hechas hoy',
          semanticsLabel: '${d.missionsDone} tareas completadas hoy',
        ),
      if (current != null)
        QuestPathNode(
          state: QuestPathState.current,
          label: current.title,
          sublabel: '+${current.xpReward} XP',
          bubble: 'EMPEZAR',
          semanticsLabel:
              '${current.title}, toca ahora, +${current.xpReward} XP. '
              'Toca para empezar en Foco',
          onTap: () => onFocus(current.id),
        ),
      for (final t in d.todayTasks)
        if (t.id != current?.id)
          QuestPathNode(
            state: QuestPathState.next,
            label: t.title,
            sublabel: t.overdue ? 'Vencida' : '+${t.xpReward} XP',
            semanticsLabel:
                '${t.title}${t.overdue ? ', vencida' : ''}. '
                'Toca para empezar en Foco',
            onTap: () => onFocus(t.id),
          ),
      _chest(d.chest),
    ];
    final at = nodes.indexWhere(
      (n) => n is QuestPathNode && n.state == QuestPathState.current,
    );
    return QuestPath(
      nodes: nodes,
      current: at < 0 ? null : at,
      celebrate: d.chest.claimed,
    );
  }

  Widget _chest(DailyChest c) {
    final progress = c.progress.clamp(0, c.required);
    return QuestPathNode(
      // Listo: dorado con su globo, sin anillo; el anillo es solo de la tarea.
      state: c.claimed || c.ready ? QuestPathState.done : QuestPathState.locked,
      icon: c.claimed ? Icons.inventory_2_outlined : Icons.redeem_rounded,
      label: c.claimed
          ? 'Cofre del día abierto'
          : c.ready
          ? '¡Abre tu cofre!'
          : 'Cofre del día',
      sublabel: c.claimed
          ? 'Mañana hay otro'
          : '$progress/${c.required} · +${c.coins} Monedas',
      semanticsLabel: c.claimed
          ? 'Cofre del día ya cobrado'
          : c.ready
          ? 'Cofre del día listo: toca para cobrar ${c.coins} Monedas'
          : 'Cofre del día: $progress de ${c.required} tareas',
      bubble: c.ready ? '¡COBRAR!' : null,
      busy: claimingChest,
      onTap: c.ready ? onClaimChest : null,
    );
  }
}
