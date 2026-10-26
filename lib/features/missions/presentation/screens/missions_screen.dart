import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/create_mission_sheet.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/mission_importance_card.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/mission_tile.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/prioritized_mission_card.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/rp_genie_tip_card.dart';

/// Misiones. Necesita un [MissionsBloc] por encima (lo provee el router).
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key, required this.onStartFocus});

  /// Abre la Mazmorra tras "Crear e iniciar Focus".
  final VoidCallback onStartFocus;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MissionsBloc, MissionsState>(
        listenWhen: (_, state) =>
            state is MissionsSuccess &&
            (state.message != null || state.focusRequested),
        listener: (context, state) {
          state as MissionsSuccess;
          if (state.message case final message?) {
            showLifeQuestMessage(context, message);
          }
          if (state.focusRequested) onStartFocus();
        },
        builder: (context, state) => switch (state) {
          MissionsInitial() || MissionsLoading() => const Center(
            child: CircularProgressIndicator(color: LifeQuestColors.deepGreen),
          ),
          MissionsFailure(:final message) => _ErrorView(
            message: message,
            onRetry: () =>
                context.read<MissionsBloc>().add(const MissionsRequested()),
          ),
          MissionsSuccess() => RefreshIndicator(
            color: LifeQuestColors.deepGreen,
            onRefresh: () => _refresh(context.read<MissionsBloc>()),
            child: _content(context, state),
          ),
        },
      );

  static Future<void> _refresh(MissionsBloc bloc) {
    bloc.add(const MissionsRequested());
    return bloc.stream.firstWhere(
      (state) => state is! MissionsSuccess || !state.refreshing,
    );
  }

  Future<void> _createMission(
    BuildContext context,
    MissionsSuccess state,
  ) async {
    final bloc = context.read<MissionsBloc>();
    final result = await showModalBottomSheet<CreateMissionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateMissionSheet(board: state.board),
    );
    if (result == null) return;
    bloc.add(MissionCreated(result.mission, startFocus: result.startFocus));
  }

  Widget _content(BuildContext context, MissionsSuccess state) {
    final now = DateTime.now();
    final missions = state.board.missions;
    final idle = state.busyMissionId == null && !state.saving;
    void complete(String id) =>
        context.read<MissionsBloc>().add(MissionCompleted(id));

    return LifeQuestPage(
      title: 'Misiones',
      subtitle: 'Cada paso cuenta para tu siguiente nivel.',
      children: [
        if (missions.isEmpty)
          const LifeQuestSurface(
            child: Text(
              'No tienes misiones abiertas. Crea la primera y da el siguiente paso.',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 12),
            ),
          )
        else ...[
          const RpGenieTipCard(),
          const SizedBox(height: 16),
          PrioritizedMissionCard(
            mission: missions.first,
            now: now,
            busy: state.busyMissionId == missions.first.id,
            onComplete: idle ? () => complete(missions.first.id) : null,
          ),
          const SizedBox(height: 14),
          const MissionImportanceCard(),
        ],
        if (missions.length > 1) ...[
          const SizedBox(height: 16),
          LifeQuestSectionHeading(
            'OTRAS MISIONES',
            action: '${missions.length - 1} activas',
          ),
          const SizedBox(height: 7),
          for (final mission in missions.skip(1)) ...[
            MissionTile(
              mission: mission,
              now: now,
              busy: state.busyMissionId == mission.id,
              onComplete: idle ? () => complete(mission.id) : null,
            ),
            const SizedBox(height: 7),
          ],
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: idle ? () => _createMission(context, state) : null,
            icon: state.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(state.saving ? 'Creando misión…' : 'Crear misión'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: LifeQuestColors.ink),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
