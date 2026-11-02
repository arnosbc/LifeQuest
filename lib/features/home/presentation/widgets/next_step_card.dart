import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_format.dart';

/// «Siguiente paso» (Main.dc.html, Misión principal): la tarea que toca ahora,
/// con su recompensa y «Empezar en Foco» (se completa dentro del Foco, 040).
class NextStepCard extends StatelessWidget {
  const NextStepCard({
    super.key,
    required this.mission,
    required this.busy,
    required this.onFocus,
    required this.onCreate,
    this.now,
  });

  /// Null: no hay tareas abiertas.
  final PriorityMission? mission;
  final bool busy;
  final VoidCallback onFocus;
  final VoidCallback onCreate;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final m = mission;
    if (m == null) {
      return QuestlyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('No tienes tareas pendientes', style: QText.title3(q.text)),
            const SizedBox(height: QSpace.xs),
            Text(
              'Anota lo próximo que quieras lograr y te ayudo a empezar.',
              style: QText.body(q.text2).copyWith(fontSize: 14),
            ),
            const SizedBox(height: QSpace.m),
            QuestlyButton(
              label: 'Crear tarea',
              icon: QIcons.plus,
              variant: QuestlyButtonVariant.tonal,
              onPressed: onCreate,
            ),
          ],
        ),
      );
    }
    final high = m.priority == UrgencyLevel.high;
    return QuestlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag(
                HomeFormat.priority(m.priority),
                high ? q.coralTint : q.tint,
                high ? q.coralInk : q.ink,
              ),
              _Tag(
                HomeFormat.due(m.dueDate, now ?? DateTime.now()),
                q.riverTint,
                q.riverInk,
              ),
            ],
          ),
          const SizedBox(height: QSpace.m),
          Text(m.title, style: QText.title2(q.text).copyWith(fontSize: 22)),
          const SizedBox(height: QSpace.m),
          Wrap(
            spacing: 6,
            children: [
              _Tag('+${m.xpReward} XP', q.tint, q.ink, number: true),
              _Tag(
                '+${m.coinReward} Monedas',
                q.mustardTint,
                q.mustardInk,
                number: true,
              ),
            ],
          ),
          const SizedBox(height: QSpace.m),
          // 040: las tareas se completan dentro del Modo Foco.
          QuestlyButton(
            label: 'Empezar en Foco',
            icon: QIcons.focus,
            onPressed: busy ? null : onFocus,
            disabledReason: 'Abriendo…',
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.bg, this.fg, {this.number = false});

  final String text;
  final Color bg;
  final Color fg;
  final bool number;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(QRadius.pill),
    ),
    child: Text(
      text,
      style: number
          ? QText.number(fg, size: 13)
          : QText.label(fg).copyWith(fontSize: 12),
    ),
  );
}
