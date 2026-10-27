import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/presentation/blocs/dungeon_bloc.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/deep_work_session_card.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/dungeon_setup_view.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/dungeon_timer_ring.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/session_rewards_card.dart';

/// Mazmorra. Necesita un [DungeonBloc] por encima (lo provee el router).
class DungeonScreen extends StatelessWidget {
  const DungeonScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<DungeonBloc, DungeonState>(
    listenWhen: (_, state) => state is DungeonReady && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as DungeonReady).message!),
    builder: (context, state) => switch (state) {
      DungeonInitial() || DungeonLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      DungeonFailure(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    context.read<DungeonBloc>().add(const DungeonRequested()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      DungeonReady() => _ready(context, state),
    },
  );

  Widget _ready(BuildContext context, DungeonReady state) {
    final bloc = context.read<DungeonBloc>();
    final session = state.board.session;
    if (session == null) {
      return LifeQuestPage(
        title: 'Mazmorra',
        subtitle: 'DEEP WORKING · Prepara tu mochila',
        children: [
          if (state.summary case final summary?) ...[
            SessionRewardsCard(
              title: 'BOTÍN DE LA ÚLTIMA SESIÓN',
              xp: summary.xp,
              coins: summary.coins,
              cycles: summary.cycles,
              minutes: summary.minutes,
            ),
            TextButton(
              onPressed: () => bloc.add(const DungeonSummaryDismissed()),
              child: const Text('Cerrar resumen'),
            ),
            const SizedBox(height: 9),
          ],
          DungeonSetupView(
            board: state.board,
            busy: state.busy,
            onStart: (total, cycle, tasks) => bloc.add(
              DungeonStarted(
                totalMinutes: total,
                cycleMinutes: cycle,
                taskIds: tasks,
              ),
            ),
          ),
        ],
      );
    }

    final rest = state.phase == DungeonPhase.rest;
    final done = state.phase == DungeonPhase.done;
    final cycle = (session.cyclesDone + (done ? 0 : 1)).clamp(
      1,
      session.maxCycles,
    );
    final total = rest
        ? state.board.breakAfter(session.cyclesDone)
        : Duration(minutes: session.cycleMinutes);
    return LifeQuestPage(
      title: 'Mazmorra',
      subtitle: 'DEEP WORKING · Ciclo $cycle / ${session.maxCycles}',
      children: [
        DungeonTimerRing(
          remaining: state.remaining,
          total: total,
          label: done
              ? 'SESIÓN COMPLETA'
              : state.paused
              ? 'EN PAUSA'
              : rest
              ? 'DESCANSO'
              : 'MAZMORRA ACTIVA',
          footer: state.busy
              ? 'Guardando tu progreso…'
              : 'Ciclo $cycle de ${session.maxCycles}',
        ),
        const SizedBox(height: 14),
        DeepWorkSessionCard(
          session: session,
          currentTaskId: state.currentTaskId,
          onSelect: (id) => bloc.add(DungeonTaskSelected(id)),
          onComplete: state.busy
              ? null
              : (id) => bloc.add(DungeonTaskCompleted(id)),
        ),
        const SizedBox(height: 9),
        SessionRewardsCard(
          title: 'RECOMPENSAS DE LA SESIÓN',
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
                  onPressed: () => bloc.add(const DungeonPauseToggled()),
                  icon: Icon(state.paused ? Icons.play_arrow : Icons.pause),
                  label: Text(state.paused ? 'Continuar' : 'Pausar'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: rest
                      ? () => bloc.add(const DungeonBreakSkipped())
                      : null,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Saltar descanso'),
                ),
              ),
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
            style: FilledButton.styleFrom(
              backgroundColor: context.lq.deepGreen,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmEnd(BuildContext context, bool done) async {
    final bloc = context.read<DungeonBloc>();
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
    if (ok) bloc.add(const DungeonEnded());
  }
}
