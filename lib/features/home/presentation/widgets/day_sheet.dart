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
    required this.onScheduleTask,
    required this.onPlanDay,
    required this.onReplan,
    required this.onCapture,
    required this.onVoice,
    required this.onConnectCalendar,
    this.onCloseDay,
    this.busyHabitId,
    this.onCompleteReminder,
    this.minHeight = 0,
  });

  /// Abre «Cierra el día» (revisión de lo pendiente).
  final VoidCallback? onCloseDay;

  /// «Hecho» de un recordatorio; null lo deja solo de lectura.
  final ValueChanged<String>? onCompleteReminder;

  final double minHeight;

  final HomeDashboard dashboard;
  final DateTime now;

  /// Abre Foco con esa tarea en la mochila.
  final ValueChanged<String> onStartFocus;
  final VoidCallback onCreateTask;
  final ValueChanged<String> onCompleteHabit;
  final VoidCallback onOpenHabits;

  /// Pone o mueve una tarea en la agenda de hoy.
  final void Function(String taskId, DateTime at) onScheduleTask;

  /// El asistente llena los huecos libres de hoy (vista previa).
  final VoidCallback onPlanDay;

  /// El asistente reubica lo atrasado (vista previa).
  final VoidCallback onReplan;

  /// Abre «Anotar»: escribir una tarea en lenguaje normal.
  final VoidCallback onCapture;

  /// Abre «Anotar» dictando.
  final VoidCallback onVoice;
  final VoidCallback onConnectCalendar;
  final String? busyHabitId;

  /// Desde esta hora Hoy invita a cerrar el día.
  static const closeHour = 19;

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
    final left = (d.tasksTotal - d.tasksDone).clamp(0, d.tasksTotal);
    final meta = [
      switch (left) {
        0 => 'Nada pendiente',
        1 => '1 pendiente',
        _ => '$left pendientes',
      },
      if (d.streakDays > 0)
        d.streakDays == 1 ? 'racha 1 día' : 'racha ${d.streakDays} días',
    ].join(' · ');
    final task = d.priorityTask;
    // El bloque en curso manda sobre la tarea sugerida: es la única fila en rojo.
    final nowBlock = d.agenda
        // Un recordatorio no es un bloque de trabajo: no se ofrece en Foco.
        .where(
          (b) =>
              !b.isReminder &&
              !b.done &&
              !now.isBefore(b.start) &&
              now.isBefore(b.end),
        )
        .firstOrNull;

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
          const SizedBox(height: 18),
          if (now.hour >= closeHour && left > 0 && onCloseDay != null) ...[
            SheetRow(
              current: true,
              title: 'Cierra el día',
              subtitle: left == 1
                  ? 'Queda 1 pendiente: decide si va mañana.'
                  : 'Quedan $left pendientes: decide qué va mañana.',
              action: SheetPill(label: 'Cerrar el día', onTap: onCloseDay),
            ),
            const SizedBox(height: 12),
          ],
          _CaptureBar(onTap: onCapture, onVoice: onVoice),
          const SizedBox(height: 16),
          _DayProgress(dashboard: d),
          const SizedBox(height: 20),
          const PaperRule(),
          const SizedBox(height: 16),
          const LifeQuestSectionHeading('Ahora'),
          if (nowBlock != null)
            SheetRow(
              current: true,
              time: _time(nowBlock.start),
              title: nowBlock.title,
              subtitle: 'Hasta las ${_time(nowBlock.end)}',
              action: SheetPill(
                label: 'Empezar foco',
                onTap: () => onStartFocus(nowBlock.id),
              ),
            )
          else if (task == null)
            LifeQuestEmptyState(
              compact: true,
              illustration: d.tasksTotal > 0
                  ? LifeQuestIllustration.done
                  : LifeQuestIllustration.blank,
              title: d.tasksTotal > 0
                  ? 'Todo listo por hoy'
                  : 'No tienes tareas pendientes',
              message: d.tasksTotal > 0
                  ? 'Cerraste lo que tocaba. Descansa o adelanta algo.'
                  : 'Anota lo siguiente que quieres hacer.',
              actionLabel: 'Crear tarea',
              onAction: onCreateTask,
            )
          else
            SheetRow(
              current: true,
              time: _time(task.dueDate),
              title: task.title,
              subtitle: '+${task.xpReward} XP',
              action: SheetPill(
                label: 'Empezar foco',
                onTap: () => onStartFocus(task.id),
              ),
            ),
          // Hábitos antes que la agenda: son de un toque y no deben quedar
          // enterrados bajo una agenda llena.
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
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final habit in d.habits)
                  _HabitChip(
                    habit: habit,
                    busy: habit.id == busyHabitId,
                    onTap: habit.done || habit.id == busyHabitId
                        ? null
                        : () => onCompleteHabit(habit.id),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          _Agenda(
            dashboard: d,
            now: now,
            onPlanDay: onPlanDay,
            onReplan: onReplan,
            onConnectCalendar: onConnectCalendar,
            onCompleteReminder: onCompleteReminder,
            onPickTime: (id, current) => _pickTime(context, id, current),
          ),
        ],
      ),
    );
  }

  /// Elige la hora de hoy para la tarea; por defecto, la próxima hora en punto.
  Future<void> _pickTime(
    BuildContext context,
    String taskId,
    DateTime? current,
  ) async {
    final next = now.add(const Duration(hours: 1));
    final time = await showTimePicker(
      context: context,
      helpText: 'Hora para hoy',
      initialTime: TimeOfDay(
        hour: (current ?? next).hour,
        minute: current?.minute ?? 0,
      ),
    );
    if (time == null) return;
    onScheduleTask(
      taskId,
      DateTime(now.year, now.month, now.day, time.hour, time.minute),
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

/// Parece un campo de texto: abre «Anotar» (la voz llega en la fase 4).
class _CaptureBar extends StatelessWidget {
  const _CaptureBar({required this.onTap, required this.onVoice});

  final VoidCallback onTap;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      label: 'Anotar una tarea',
      excludeSemantics: true,
      child: Material(
        color: q.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.card),
          side: BorderSide(color: q.line),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QRadius.card),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20, color: q.text2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Escribe o dicta: «gym mañana 6pm»',
                      style: QText.body(q.text2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dictar una tarea',
                    onPressed: onVoice,
                    icon: Icon(Icons.mic_none_rounded, color: q.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Invita a conectar el calendario antes de pedir el permiso del sistema.
class _ConnectCalendar extends StatelessWidget {
  const _ConnectCalendar({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LifeQuestSurface(
        color: q.tint,
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Conecta tu calendario y la agenda no chocará con tus '
                'eventos. Solo se lee en tu teléfono; no se sube.',
                style: QText.body(q.text2),
              ),
            ),
            TextButton(
              onPressed: onConnect,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Conectar'),
            ),
          ],
        ),
      ),
    );
  }
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
                  value: '${d.tasksDone}/${d.tasksTotal}',
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

/// Hábito de hoy como chip: un toque lo marca. Hecho = relleno con check.
class _HabitChip extends StatelessWidget {
  const _HabitChip({required this.habit, required this.busy, this.onTap});

  final TodayHabit habit;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final ink = habit.done ? q.onStrong : q.text;
    return Semantics(
      button: onTap != null,
      checked: habit.done,
      label: habit.done
          ? '${habit.name}, hecho hoy'
          : 'Marcar ${habit.name} como hecho',
      excludeSemantics: true,
      child: Material(
        color: habit.done ? q.strong : q.card,
        shape: StadiumBorder(
          side: habit.done
              ? BorderSide.none
              : BorderSide(color: q.inputBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: QSize.minTap),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: busy
                        ? CircularProgressIndicator(strokeWidth: 2, color: ink)
                        : Icon(
                            habit.done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: ink,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      habit.name,
                      overflow: TextOverflow.ellipsis,
                      style: QText.label(ink).copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Agenda de hoy en una sola línea de tiempo (eventos del teléfono y
/// bloques). Plegada muestra solo lo que viene; lo pasado, lo hecho y las
/// tareas sin hora una por una se abren con «Ver toda la agenda».
class _Agenda extends StatefulWidget {
  const _Agenda({
    required this.dashboard,
    required this.now,
    required this.onPlanDay,
    required this.onReplan,
    required this.onConnectCalendar,
    required this.onPickTime,
    this.onCompleteReminder,
  });

  final HomeDashboard dashboard;
  final DateTime now;
  final VoidCallback onPlanDay;
  final VoidCallback onReplan;
  final VoidCallback onConnectCalendar;
  final ValueChanged<String>? onCompleteReminder;
  final void Function(String taskId, DateTime? current) onPickTime;

  /// Cuántas entradas próximas se ven plegada.
  static const preview = 3;

  @override
  State<_Agenda> createState() => _AgendaState();
}

class _AgendaState extends State<_Agenda> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final d = widget.dashboard;
    final now = widget.now;
    String time(DateTime t) => DaySheet._time(t);

    final entries = <({DateTime start, bool upcoming, Widget row})>[
      for (final event in d.events)
        (
          start: event.start,
          upcoming: event.end.isAfter(now),
          row: SheetRow(
            leading: const SizedBox(
              width: 24,
              child: Icon(Icons.event_outlined, size: 20),
            ),
            time: time(event.start),
            title: event.title,
            subtitle: 'Calendario · hasta las ${time(event.end)}',
            muted: event.end.isBefore(now),
          ),
        ),
      for (final block in d.agenda)
        (
          start: block.start,
          upcoming:
              !block.done &&
              (block.isReminder ? block.start : block.end).isAfter(now),
          row: SheetRow(
            // Solo un recordatorio se marca aquí; una tarea se termina en
            // Tareas o en Foco, no con un check que parece de selección.
            leading: block.isReminder
                ? SheetCheck(
                    done: block.done,
                    label: block.done
                        ? '${block.title}, hecho'
                        : 'Marcar «${block.title}» como hecho',
                    onTap: !block.done && widget.onCompleteReminder != null
                        ? () => widget.onCompleteReminder!(block.id)
                        : null,
                  )
                : null,
            time: time(block.start),
            timeIcon: block.isReminder
                ? Icons.notifications_none_rounded
                : null,
            title: block.title,
            subtitle: [
              if (block.isReminder)
                'Recordatorio'
              else
                'Hasta las ${time(block.end)}',
              if (block.repeats) 'se repite',
            ].join(' · '),
            done: block.done,
            muted:
                !block.done &&
                (block.isReminder ? block.start : block.end).isBefore(now),
            trailing: block.done
                ? null
                : IconButton(
                    tooltip: 'Mover «${block.title}»',
                    onPressed: () => widget.onPickTime(block.id, block.start),
                    icon: Icon(Icons.schedule_rounded, color: q.text2),
                  ),
          ),
        ),
    ]..sort((a, b) => a.start.compareTo(b.start));

    final upcoming = entries.where((e) => e.upcoming).toList();
    final shown = _open ? entries : upcoming.take(_Agenda.preview).toList();
    final folded = entries.length - shown.length;
    final late = d.agenda.any(
      (b) => !b.isReminder && !b.done && b.end.isBefore(now),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LifeQuestSectionHeading(
          upcoming.isEmpty ? 'Agenda' : 'Agenda · ${upcoming.length} por venir',
          action: late ? 'Replanificar' : null,
          onTap: late ? widget.onReplan : null,
        ),
        if (d.calendarAccess == CalendarAccess.notAsked)
          _ConnectCalendar(onConnect: widget.onConnectCalendar),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Nada con hora hoy. Ponle hora a una tarea y te avisamos.',
              style: QText.body(q.text2),
            ),
          )
        else if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No queda nada con hora por hoy.',
              style: QText.body(q.text2),
            ),
          ),
        for (final e in shown) e.row,
        if (d.unscheduled.isNotEmpty)
          SheetRow(
            title: d.unscheduled.length == 1
                ? '1 tarea sin hora'
                : '${d.unscheduled.length} tareas sin hora',
            subtitle: d.unscheduled.map((t) => t.title).take(3).join(' · '),
            action: SheetPill(label: 'Armar mi día', onTap: widget.onPlanDay),
          ),
        if (_open)
          // shortcut: solo las 5 primeras; la lista completa vive en Tareas.
          for (final task in d.unscheduled.take(5))
            SheetRow(
              title: task.title,
              subtitle: task.isReminder ? 'Recordatorio sin hora' : 'Sin hora',
              trailing: IconButton(
                tooltip: 'Poner hora a «${task.title}»',
                onPressed: () => widget.onPickTime(task.id, null),
                icon: Icon(Icons.schedule_rounded, color: q.text2),
              ),
            ),
        if (folded > 0 || _open || d.unscheduled.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _open = !_open),
              icon: Icon(
                _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              ),
              label: Text(
                _open
                    ? 'Ver menos'
                    : folded > 0
                    ? 'Ver toda la agenda · $folded más'
                    : 'Poner hora una por una',
              ),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ),
      ],
    );
  }
}
