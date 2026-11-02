import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_format.dart';

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
    required this.onOpenHabits,
    this.busyHabitId,
    this.minHeight = 0,
  });

  final double minHeight;

  final HomeDashboard dashboard;
  final DateTime now;
  final VoidCallback onStartFocus;
  final VoidCallback onCreateTask;
  final ValueChanged<String> onCompleteHabit;
  final VoidCallback onOpenHabits;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(now, d.displayName),
                            style: QText.body(q.text2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _capitalize(weekdays[now.weekday - 1]),
                            style: QText.display(q.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${now.day} de ${months[now.month - 1]}',
                            style: QText.title3(q.text2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CalendarTile(
                      day: now.day,
                      month: months[now.month - 1].substring(0, 3),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(meta, style: QText.body(q.text2)),
                const SizedBox(height: 16),
                _WeekStrip(now: now),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _DayProgress(dashboard: d),
          const SizedBox(height: 20),
          const PaperRule(),
          const SizedBox(height: 16),
          const LifeQuestSectionHeading('Ahora'),
          if (mission == null)
            LifeQuestEmptyState(
              compact: true,
              illustration: d.missionsTotal > 0
                  ? LifeQuestIllustration.done
                  : LifeQuestIllustration.blank,
              title: d.missionsTotal > 0
                  ? 'Todo listo por hoy'
                  : 'No tienes tareas pendientes',
              message: d.missionsTotal > 0
                  ? 'Cerraste lo que tocaba. Descansa o adelanta algo.'
                  : 'Anota lo siguiente que quieres hacer.',
              actionLabel: 'Crear tarea',
              onAction: onCreateTask,
            )
          else
            SheetRow(
              current: true,
              leading: const SheetCheck(done: false),
              time: _time(mission.dueDate),
              title: mission.title,
              subtitle: '+${mission.xpReward} XP',
              action: SheetPill(label: 'Empezar foco', onTap: onStartFocus),
            ),
          const SizedBox(height: 20),
          LifeQuestSectionHeading(
            d.habitsTotal == 0
                ? 'Hábitos de hoy'
                : 'Hábitos de hoy · ${d.habitsDone}/${d.habitsTotal}',
            action: 'Ver todos',
            onTap: onOpenHabits,
          ),
          if (d.habits.isEmpty)
            LifeQuestEmptyState(
              compact: true,
              illustration: LifeQuestIllustration.sprout,
              title: 'Aún no tienes hábitos para hoy',
              message: 'Empieza por uno pequeño que puedas repetir.',
              actionLabel: 'Crear hábito',
              onAction: onOpenHabits,
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

  static String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  static String _greeting(DateTime now, String? name) {
    final hello = switch (now.hour) {
      < 12 => 'Buenos días',
      < 20 => 'Buenas tardes',
      _ => 'Buenas noches',
    };
    final first = name?.trim().split(' ').first ?? '';
    return first.isEmpty ? hello : '$hello, $first';
  }

  static String _time(DateTime? due) => due == null
      ? ''
      : '${due.hour.toString().padLeft(2, '0')}:'
            '${due.minute.toString().padLeft(2, '0')}';
}

/// Resumen del día en un bloque: tareas, hábitos y foco, y el nivel debajo.
class _DayProgress extends StatelessWidget {
  const _DayProgress({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final d = dashboard;
    final xp = d.xpToNextLevel <= 0
        ? 0.0
        : (d.currentXp / d.xpToNextLevel).clamp(0.0, 1.0);
    return LifeQuestSurface(
      color: q.tint,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LifeQuestStat(
                  value: '${d.missionsDone}/${d.missionsTotal}',
                  label: 'Tareas',
                ),
              ),
              Expanded(
                child: LifeQuestStat(
                  value: '${d.habitsDone}/${d.habitsTotal}',
                  label: 'Hábitos',
                ),
              ),
              Expanded(
                child: LifeQuestStat(
                  value: HomeFormat.minutes(d.focusMinutes),
                  label: 'Foco',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Nivel ${d.level}, ${d.currentXp} de ${d.xpToNextLevel} XP',
            excludeSemantics: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Nivel ${d.level}', style: QText.meta(q.text)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${HomeFormat.number(d.currentXp)} / '
                        '${HomeFormat.number(d.xpToNextLevel)} XP',
                        textAlign: TextAlign.end,
                        style: QText.number(q.text2, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: xp,
                    minHeight: 6,
                    color: q.text,
                    backgroundColor: q.line,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja de calendario en miniatura: el mes en una franja roja y el día debajo.
class _CalendarTile extends StatelessWidget {
  const _CalendarTile({required this.day, required this.month});

  final int day;
  final String month;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      width: 68,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: q.card,
        borderRadius: BorderRadius.circular(QRadius.card),
        border: Border.all(color: q.text, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: q.mark,
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              month.toUpperCase(),
              textAlign: TextAlign.center,
              style: QText.meta(q.card),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: FittedBox(
              child: Text('$day', style: QText.numeral(q.text, size: 36)),
            ),
          ),
        ],
      ),
    );
  }
}

/// La semana en curso (lunes a domingo) con hoy marcado en rojo.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.now});

  final DateTime now;

  static const _initials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final day = DateTime(monday.year, monday.month, monday.day + i);
                final today = i == now.weekday - 1;
                final past = i < now.weekday - 1;
                return Column(
                  children: [
                    Text(
                      _initials[i],
                      style: QText.meta(today ? q.mark : q.text2),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: today ? q.mark : null,
                      ),
                      child: FittedBox(
                        child: Text(
                          '${day.day}',
                          style:
                              QText.number(
                                today
                                    ? q.card
                                    : past
                                    ? q.text2
                                    : q.text,
                              ).copyWith(
                                fontWeight: today ? FontWeight.w800 : null,
                              ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
