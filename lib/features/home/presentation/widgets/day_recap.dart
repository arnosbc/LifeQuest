import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Repaso del día: sale al completar lo último pendiente (ver [dayComplete]).
/// Nevi resume lo logrado y se despide hasta mañana.
Future<void> showDayRecap(BuildContext context, HomeDashboard d) {
  final q = context.q;
  String plural(int n, String one, String many) => n == 1 ? one : many;
  final rows = [
    if (d.missionsDone > 0)
      (
        QIcons.flag,
        '${d.missionsDone} ${plural(d.missionsDone, 'tarea', 'tareas')}',
      ),
    if (d.habitsTotal > 0)
      (QIcons.leaf, '${d.habitsDone} de ${d.habitsTotal} hábitos'),
    if (d.dailyXp > 0) (QIcons.star, '${d.dailyXp} XP ganada'),
    if (d.dailyXpGoal case final goal? when d.dailyXp >= goal)
      (QIcons.trophy, 'Meta diaria cumplida: $goal XP'),
    if (d.focusMinutes > 0) (QIcons.focus, '${d.focusMinutes} min de Foco'),
    if (d.streakDays > 0)
      (
        QIcons.flame,
        'Racha de ${d.streakDays} ${plural(d.streakDays, 'día', 'días')}',
      ),
  ];
  return showQuestlyDialog<void>(
    context,
    title: '¡Día completo!',
    message: 'Hiciste todo lo de hoy. Descansa: mañana seguimos juntos.',
    content: Padding(
      padding: const EdgeInsets.only(bottom: QSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: MascotPose(pose: 'durmiendo', size: 110)),
          const SizedBox(height: QSpace.s),
          for (final (icon, text) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  QIcon(icon, color: q.accent, size: 18),
                  const SizedBox(width: QSpace.s),
                  Expanded(child: Text(text, style: QText.body(q.text))),
                ],
              ),
            ),
        ],
      ),
    ),
    actions: [
      Builder(
        builder: (context) => QuestlyButton(
          label: 'Hasta mañana',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ],
  );
}
