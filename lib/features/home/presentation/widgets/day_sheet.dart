import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// La hoja de hoy: el número del día en rojo, lo que queda y lo que toca.
/// La tarea de ahora es la única fila marcada en rojo.
class DaySheet extends StatelessWidget {
  const DaySheet({
    super.key,
    required this.dashboard,
    required this.now,
    required this.onStartFocus,
    required this.onCreateTask,
    required this.onCompleteHabit,
    this.busyHabitId,
    this.minHeight = 0,
  });

  final double minHeight;

  final HomeDashboard dashboard;
  final DateTime now;
  final VoidCallback onStartFocus;
  final VoidCallback onCreateTask;
  final ValueChanged<String> onCompleteHabit;
  final String? busyHabitId;

  static const weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  static const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final d = dashboard;
    final left = (d.missionsTotal - d.missionsDone).clamp(0, d.missionsTotal);
    final meta = [
      switch (left) {
        0 => 'Nada pendiente',
        1 => '1 pendiente',
        _ => '$left pendientes',
      },
      if (d.streakDays > 0)
        d.streakDays == 1 ? 'racha 1 día' : 'racha ${d.streakDays} días',
    ].join(' · ');
    final mission = d.priorityMission;

    return PaperSheet(
      bound: true,
      minHeight: minHeight,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label:
                'Hoy, ${weekdays[now.weekday - 1]} ${now.day} de '
                '${months[now.month - 1]}. $meta',
            excludeSemantics: true,
            child: Column(
              children: [
                FittedBox(
                  child: Text('${now.day}', style: QText.numeral(q.mark)),
                ),
                const SizedBox(height: 14),
                Text(
                  '${weekdays[now.weekday - 1]} · ${months[now.month - 1]} '
                  '${now.year}',
                  style: QText.title3(q.text),
                ),
                const SizedBox(height: 6),
                Text(meta, style: QText.body(q.text2)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const PaperRule(),
          const SizedBox(height: 4),
          if (mission == null)
            SheetRow(
              leading: const SizedBox(width: 48),
              time: '',
              title: 'No tienes tareas pendientes',
              muted: true,
              action: SheetPill(label: 'Crear tarea', onTap: onCreateTask),
            )
          else
            SheetRow(
              current: true,
              leading: const SheetCheck(done: false),
              time: _time(mission.dueDate),
              title: mission.title,
              action: SheetPill(label: 'Empezar foco', onTap: onStartFocus),
            ),
          for (final habit in d.habits)
            SheetRow(
              leading: SheetCheck(
                done: habit.done,
                busy: habit.id == busyHabitId,
                label: habit.done
                    ? '${habit.name}, hecho hoy'
                    : 'Marcar ${habit.name} como hecho',
                onTap: habit.done || habit.id == busyHabitId
                    ? null
                    : () => onCompleteHabit(habit.id),
              ),
              time: '',
              timeIcon: Icons.repeat_rounded,
              title: habit.name,
              done: habit.done,
            ),
        ],
      ),
    );
  }

  static String _time(DateTime? due) => due == null
      ? ''
      : '${due.hour.toString().padLeft(2, '0')}:'
            '${due.minute.toString().padLeft(2, '0')}';
}
