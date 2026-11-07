import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either;

import 'package:proyecto_movil/core/errors/failures.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_guide.dart';
import 'package:proyecto_movil/features/focus/presentation/blocs/focus_bloc.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/deep_work_session_card.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/focus_progress_widgets.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/focus_setup_view.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/focus_timer_ring.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/session_rewards_card.dart';

/// Foco. Necesita un [FocusBloc] por encima (lo provee el router).
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, this.preselectedTaskId, this.suggestSteps});

  /// El asistente propone los pasos de una tarea; null oculta el botón.
  final Future<Either<Failure, List<String>>> Function(String title)?
  suggestSteps;

  /// Tarea elegida en Hoy o en Tareas con «Empezar foco».
  final String? preselectedTaskId;

  @override
  Widget build(BuildContext context) => BlocConsumer<FocusBloc, FocusState>(
    listenWhen: (_, state) => state is FocusReady && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as FocusReady).message!),
    builder: (context, state) => switch (state) {
      FocusInitial() || FocusLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      FocusFailure(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    context.read<FocusBloc>().add(const FocusRequested()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      FocusReady() => _ready(context, state),
    },
  );

  Widget _ready(BuildContext context, FocusReady state) {
    final bloc = context.read<FocusBloc>();
    final session = state.board.session;
    if (session == null) {
      return LifeQuestPage(
        title: 'Foco',
        subtitle: 'Elige qué harás y cuánto tiempo.',
        children: [
          if (state.summary case final summary?) ...[
            SessionStoryCard(
              summary: summary,
              busy: state.busy,
              scheduledAt: state.nextScheduledAt,
              onSchedule: (id) => _scheduleTomorrow(context, id),
            ),
            TextButton(
              onPressed: () => bloc.add(const FocusSummaryDismissed()),
              child: const Text('Cerrar resumen'),
            ),
            const SizedBox(height: 9),
          ],
          FocusSetupView(
            board: state.board,
            preselected: preselectedTaskId,
            onQuickStart: (id) => bloc.add(FocusQuickStarted(id)),
            busy: state.busy,
            onStart: (total, cycle, tasks, intention) => bloc.add(
              FocusStarted(
                totalMinutes: total,
                cycleMinutes: cycle,
                taskIds: tasks,
                intention: intention,
              ),
            ),
          ),
        ],
      );
    }

    final rest = state.phase == FocusPhase.rest;
    // Misma regla que FocusBoard.breakAfter.
    final longBreak =
        rest &&
        session.cyclesDone > 0 &&
        session.cyclesDone % state.board.longBreakEveryNCycles == 0;
    final done = state.phase == FocusPhase.done;
    final cycle = (session.cyclesDone + (done ? 0 : 1)).clamp(
      1,
      session.maxCycles,
    );
    final total = rest
        ? state.board.breakAfter(session.cyclesDone)
        : Duration(minutes: session.cycleMinutes);
    final q = context.q;
    final accent = done
        ? q.mustard
        : state.paused
        ? q.text2
        : rest
        ? q.riverInk
        : q.mark;
    final focused = session.tasks
        .where((t) => t.id == state.currentTaskId && !t.done)
        .firstOrNull;
    return LifeQuestPage(
      title: 'Foco',
      subtitle: 'Ciclo $cycle de ${session.maxCycles}',
      children: [
        FocusTimerRing(
          remaining: state.remaining,
          total: total,
          accent: accent,
          label: done
              ? 'Sesión completa'
              : state.paused
              ? 'En pausa'
              : rest
              ? 'Descanso'
              : 'Foco',
          footer: state.busy ? 'Guardando tu progreso…' : '',
        ),
        const SizedBox(height: 16),
        CycleTrack(
          total: session.maxCycles,
          done: session.cyclesDone,
          accent: accent,
        ),
        if (!done && !rest) ...[
          const SizedBox(height: 8),
          CycleIntention(
            intention:
                state.intention ?? focused?.nextStep?.title ?? focused?.title,
            onEdit: () => _editIntention(context, state.intention),
          ),
        ],
        if (rest) ...[
          const SizedBox(height: 16),
          BreakGuideCard(
            tip: FocusGuide.breakTip(session.cyclesDone, long: longBreak),
            longBreak: longBreak,
            next: focused == null
                ? null
                : focused.nextStep == null
                ? focused.title
                : '${focused.title} · ${focused.nextStep!.title}',
            intention: state.intention ?? focused?.nextStep?.title,
            onChangeIntention: () => _editIntention(context, state.intention),
          ),
        ],
        if (state.board.progress case final progress?) ...[
          const SizedBox(height: 16),
          LiveProgressCard(
            progress: progress,
            sessionXp: session.xpEarned,
            gainXp: state.gain?.xp,
            levelUp: state.gain?.levelUp ?? false,
            gainSeq: state.gain?.seq ?? 0,
          ),
        ],
        if (focused != null && !done && !rest) ...[
          const SizedBox(height: 16),
          FocusTaskCard(
            task: focused,
            heading: 'Ahora mismo',
            accent: accent,
            busy: state.busy,
            onCompleteStep: (id) => bloc.add(FocusStepCompleted(id)),
            onAddStep: () => _addStep(context, focused.id),
            onSuggestSteps: suggestSteps == null
                ? null
                : () => _suggestSteps(context, focused.id, focused.title),
          ),
        ],
        const SizedBox(height: 14),
        DeepWorkSessionCard(
          session: session,
          currentTaskId: state.currentTaskId,
          onSelect: (id) => bloc.add(FocusTaskSelected(id)),
          onComplete: state.busy
              ? null
              : (id) => bloc.add(FocusTaskCompleted(id)),
        ),
        const SizedBox(height: 9),
        if (done)
          SessionRewardsCard(
            title: 'Resumen de la sesión',
            xp: session.xpEarned,
            coins: session.coinsEarned,
            cycles: session.cyclesDone,
            minutes: session.cyclesDone * session.cycleMinutes,
          ),
        const SizedBox(height: 11),
        if (!done)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => bloc.add(const FocusPauseToggled()),
                  icon: Icon(state.paused ? Icons.play_arrow : Icons.pause),
                  label: Text(state.paused ? 'Continuar' : 'Pausar'),
                ),
              ),
              // Saltar solo existe durante el descanso: en foco no hay nada
              // que saltar y un botón apagado solo hace ruido.
              if (rest) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => bloc.add(const FocusBreakSkipped()),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Saltar descanso'),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: state.busy ? null : () => _confirmEnd(context, done),
            icon: const Icon(Icons.stop),
            label: const Text('Finalizar sesión'),
          ),
        ),
      ],
    );
  }

  Future<void> _editIntention(BuildContext context, String? current) async {
    final bloc = context.read<FocusBloc>();
    final text = await askLifeQuestText(
      context,
      title: 'Meta del ciclo',
      label: '¿Qué vas a terminar?',
      confirmLabel: 'Guardar',
      initial: current ?? '',
      maxLength: 120,
    );
    if (text != null) bloc.add(FocusIntentionChanged(text));
  }

  Future<void> _suggestSteps(
    BuildContext context,
    String taskId,
    String title,
  ) async {
    final bloc = context.read<FocusBloc>();
    final result = await suggestSteps!(title);
    if (!context.mounted) return;
    result.match(
      (failure) => showLifeQuestMessage(context, failure.message),
      (titles) => bloc.add(FocusStepsAdded(taskId: taskId, titles: titles)),
    );
  }

  Future<void> _addStep(BuildContext context, String taskId) async {
    final bloc = context.read<FocusBloc>();
    final title = await askLifeQuestText(
      context,
      title: 'Nuevo paso',
      label: 'Algo que puedas hacer en minutos',
      confirmLabel: 'Añadir',
    );
    if (title != null && title.trim().isNotEmpty) {
      bloc.add(FocusStepAdded(taskId: taskId, title: title));
    }
  }

  /// Mañana a la hora que elija (por defecto 9:00).
  Future<void> _scheduleTomorrow(BuildContext context, String taskId) async {
    final bloc = context.read<FocusBloc>();
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Mañana, ¿a qué hora?',
    );
    if (time == null) return;
    final now = DateTime.now();
    bloc.add(
      FocusNextScheduled(
        taskId: taskId,
        at: DateTime(now.year, now.month, now.day + 1, time.hour, time.minute),
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context, bool done) async {
    final bloc = context.read<FocusBloc>();
    final ok =
        done ||
        (await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('¿Terminar la sesión?'),
                content: const Text(
                  'Conservas todo lo ganado. El ciclo en curso no se cobra.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Seguir'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Terminar'),
                  ),
                ],
              ),
            ) ??
            false);
    if (ok) bloc.add(const FocusEnded());
  }
}
