import 'dart:async';

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/cycle_duration_card.dart';

/// Nivel y XP en vivo: la barra avanza y aparece «+N XP» al ganar.
class LiveProgressCard extends StatefulWidget {
  const LiveProgressCard({
    super.key,
    required this.progress,
    required this.sessionXp,
    this.gainXp,
    this.levelUp = false,
    this.gainSeq = 0,
  });

  final FocusProgress progress;

  /// XP de los ciclos de esta sesión.
  final int sessionXp;
  final int? gainXp;
  final bool levelUp;

  /// Cambia con cada ganancia nueva; dispara el «+N XP».
  final int gainSeq;

  @override
  State<LiveProgressCard> createState() => _LiveProgressCardState();
}

class _LiveProgressCardState extends State<LiveProgressCard> {
  bool _showGain = false;
  Timer? _hide;

  @override
  void didUpdateWidget(LiveProgressCard old) {
    super.didUpdateWidget(old);
    if (widget.gainSeq != old.gainSeq && widget.gainXp != null) {
      setState(() => _showGain = true);
      _hide?.cancel();
      _hide = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _showGain = false);
      });
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final p = widget.progress;
    final gain = widget.levelUp
        ? '¡Nivel ${p.level}!'
        : '+${widget.gainXp ?? 0} XP';
    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Nivel ${p.level}', style: QText.title3(q.text)),
              const SizedBox(width: 8),
              // El aviso se anuncia al lector de pantalla y se desvanece.
              Semantics(
                liveRegion: true,
                label: _showGain ? gain : null,
                child: AnimatedOpacity(
                  duration: context.motion(QMotion.sheet),
                  curve: QMotion.easeOut,
                  opacity: _showGain ? 1 : 0,
                  child: AnimatedSlide(
                    duration: context.motion(QMotion.sheet),
                    curve: QMotion.easeOut,
                    offset: _showGain ? Offset.zero : const Offset(0, 0.4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: q.mustardTint,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(gain, style: QText.label(q.mustardInk)),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${p.currentXp} / ${p.xpToNextLevel} XP',
                style: QText.meta(q.text2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label:
                '${p.currentXp} de ${p.xpToNextLevel} XP para el nivel '
                '${p.level + 1}',
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: p.fraction),
                duration: context.motion(const Duration(milliseconds: 600)),
                curve: QMotion.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: q.mustard,
                  backgroundColor: q.line,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.sessionXp == 0
                ? 'Cada ciclo, paso y tarea que termines suma aquí.'
                : 'Esta sesión llevas +${widget.sessionXp} XP en ciclos.',
            style: QText.meta(q.text2),
          ),
        ],
      ),
    );
  }
}

/// La tarea en foco con sus pasos: se marcan mientras corre el reloj.
class FocusTaskCard extends StatelessWidget {
  const FocusTaskCard({
    super.key,
    required this.task,
    required this.heading,
    required this.accent,
    required this.busy,
    required this.onCompleteStep,
    required this.onAddStep,
    this.onSuggestSteps,
  });

  /// El asistente propone los pasos; null oculta el botón.
  final Future<void> Function()? onSuggestSteps;

  final FocusTask task;
  final String heading;
  final Color accent;
  final bool busy;
  final ValueChanged<String> onCompleteStep;
  final VoidCallback onAddStep;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final steps = task.steps;
    return LifeQuestSurface(
      color: q.tint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: QText.meta(accent)),
          const SizedBox(height: 4),
          Text(task.title, style: QText.title2(q.text)),
          if (steps.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              onSuggestSteps == null
                  ? 'Sin pasos todavía. Añade el primero.'
                  : 'Sin pasos todavía. Deja que el asistente la divida.',
              style: QText.meta(q.text2),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: task.stepsDone / steps.length),
                      duration: context.motion(
                        const Duration(milliseconds: 400),
                      ),
                      curve: QMotion.easeOut,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        color: accent,
                        backgroundColor: q.line,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${task.stepsDone} de ${steps.length} pasos',
                  style: QText.meta(q.text2),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final step in steps)
              SheetRow(
                done: step.done,
                current: step == task.nextStep,
                leading: SheetCheck(
                  done: step.done,
                  label: 'Hecho: «${step.title}»',
                  onTap: step.done || busy
                      ? null
                      : () => onCompleteStep(step.id),
                ),
                title: step.title,
              ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              if (steps.isEmpty && onSuggestSteps != null)
                _SuggestStepsButton(enabled: !busy, onPressed: onSuggestSteps!),
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: busy ? null : onAddStep,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Añadir paso'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Descanso guiado: qué hacer ahora y qué toca al volver.
class BreakGuideCard extends StatelessWidget {
  const BreakGuideCard({
    super.key,
    required this.tip,
    required this.longBreak,
    required this.next,
    required this.intention,
    required this.onChangeIntention,
  });

  final String tip;
  final bool longBreak;

  /// Paso o tarea que sigue; null si ya no queda nada abierto.
  final String? next;
  final String? intention;
  final VoidCallback onChangeIntention;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return LifeQuestSurface(
      color: q.riverTint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            longBreak ? 'DESCANSO LARGO' : 'DESCANSO',
            style: QText.meta(q.riverInk),
          ),
          const SizedBox(height: 4),
          Text(tip, style: QText.title3(q.text)),
          if (next != null) ...[
            const SizedBox(height: 12),
            Text('Al volver', style: QText.meta(q.text2)),
            const SizedBox(height: 2),
            Text(next!, style: QText.body(q.text)),
          ],
          const SizedBox(height: 12),
          Text('Meta del próximo ciclo', style: QText.meta(q.text2)),
          const SizedBox(height: 2),
          Text(
            intention ?? 'Sin meta. Elige una cosa concreta para terminar.',
            style: QText.body(intention == null ? q.text2 : q.text),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: onChangeIntention,
              child: Text(intention == null ? 'Poner meta' : 'Cambiar meta'),
            ),
          ),
        ],
      ),
    );
  }
}

/// La meta del ciclo en curso, con un toque para cambiarla.
class CycleIntention extends StatelessWidget {
  const CycleIntention({
    super.key,
    required this.intention,
    required this.onEdit,
  });

  final String? intention;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      label: intention == null
          ? 'Poner meta para este ciclo'
          : 'Meta de este ciclo: $intention. Toca para cambiarla.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: q.text2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  intention == null
                      ? '¿Qué vas a terminar en este ciclo?'
                      : 'Meta: $intention',
                  style: QText.body(intention == null ? q.text2 : q.text),
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: q.text2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resumen que cuenta la sesión: qué terminaste, cómo va tu semana y qué
/// sigue mañana.
class SessionStoryCard extends StatelessWidget {
  const SessionStoryCard({
    super.key,
    required this.summary,
    required this.busy,
    required this.scheduledAt,
    required this.onSchedule,
  });

  final FocusSummary summary;
  final bool busy;
  final DateTime? scheduledAt;
  final ValueChanged<String> onSchedule;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final s = summary;
    final done = s.tasks.where((t) => t.done).length;
    final steps = s.tasks.fold<int>(0, (a, t) => a + t.stepsDone);
    final next = s.next;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu última sesión', style: QText.title3(q.text)),
          const SizedBox(height: 4),
          Text(_headline(done, steps), style: QText.body(q.text2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LifeQuestStat(
                  value: CycleDurationCard.hours(s.minutes),
                  label: 'En foco',
                ),
              ),
              Expanded(
                child: LifeQuestStat(value: '${s.cycles}', label: 'Ciclos'),
              ),
              Expanded(
                child: LifeQuestStat(value: '+${s.xp}', label: 'XP en ciclos'),
              ),
            ],
          ),
          if (s.tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final t in s.tasks)
              SheetRow(
                done: t.done,
                leading: SheetCheck(done: t.done),
                title: t.title,
                subtitle: t.steps.isEmpty
                    ? null
                    : '${t.stepsDone} de ${t.steps.length} pasos',
              ),
          ],
          const SizedBox(height: 12),
          Text(_week(s), style: QText.body(q.text)),
          if (next != null) ...[
            const SizedBox(height: 16),
            Text('Qué sigue', style: QText.meta(q.text2)),
            const SizedBox(height: 2),
            Text(
              next.nextStep == null
                  ? next.title
                  : '${next.title} · ${next.nextStep!.title}',
              style: QText.body(q.text),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: scheduledAt == null
                  ? OutlinedButton.icon(
                      onPressed: busy ? null : () => onSchedule(next.id),
                      icon: const Icon(Icons.event_outlined, size: 20),
                      label: const Text('Agendar para mañana'),
                    )
                  : Row(
                      children: [
                        Icon(Icons.check_rounded, color: q.text, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'En tu agenda: '
                            '${LifeQuestDates.dayTime(scheduledAt!)}',
                            style: QText.body(q.text),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  static String _headline(int done, int steps) {
    if (done == 0 && steps == 0) {
      return 'Avanzaste sin cerrar nada todavía: el tiempo en foco cuenta.';
    }
    final parts = [
      if (done > 0)
        '$done ${done == 1 ? 'tarea terminada' : 'tareas terminadas'}',
      if (steps > 0) '$steps ${steps == 1 ? 'paso hecho' : 'pasos hechos'}',
    ];
    return '${parts.join(' y ')}. ¡Bien hecho!';
  }

  static String _week(FocusSummary s) {
    final week = CycleDurationCard.hours(s.weekMinutes);
    if (s.prevWeekMinutes == 0) return 'Esta semana llevas $week en foco.';
    final diff = s.weekMinutes - s.prevWeekMinutes;
    final than = CycleDurationCard.hours(diff.abs());
    return diff >= 0
        ? 'Esta semana llevas $week en foco, $than más que la anterior.'
        : 'Esta semana llevas $week en foco; te faltan $than para igualar '
              'la anterior.';
  }
}

/// «Dividir en pasos» con su espera mientras responde el asistente.
class _SuggestStepsButton extends StatefulWidget {
  const _SuggestStepsButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  State<_SuggestStepsButton> createState() => _SuggestStepsButtonState();
}

class _SuggestStepsButtonState extends State<_SuggestStepsButton> {
  bool _thinking = false;

  Future<void> _run() async {
    setState(() => _thinking = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    onPressed: widget.enabled && !_thinking ? _run : null,
    icon: _thinking
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.auto_awesome_outlined, size: 20),
    label: Text(_thinking ? 'Pensando los pasos…' : 'Dividir en pasos'),
  );
}
