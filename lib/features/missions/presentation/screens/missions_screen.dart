import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/create_mission_sheet.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/missions_format.dart';

/// Tareas. Necesita un [MissionsBloc] por encima (lo provee el router).
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({
    super.key,
    required this.onStartFocus,
    required this.onOpenProjects,
  });

  /// Abre Foco tras «Crear y empezar foco».
  final VoidCallback onStartFocus;

  /// Abre Proyectos y metas.
  final VoidCallback onOpenProjects;

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
          MissionsInitial() || MissionsLoading() => Center(
            child: CircularProgressIndicator(color: context.lq.green),
          ),
          MissionsFailure(:final message) => LifeQuestErrorView(
            message: message,
            onRetry: () =>
                context.read<MissionsBloc>().add(const MissionsRequested()),
          ),
          MissionsSuccess() => RefreshIndicator(
            color: context.lq.green,
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
    Widget menu(Mission mission) => LifeQuestItemMenu(
      name: mission.title,
      enabled: idle,
      onRename: (title) =>
          context.read<MissionsBloc>().add(MissionRenamed(mission.id, title)),
      onDelete: () =>
          context.read<MissionsBloc>().add(MissionDeleted(mission.id)),
      deleteMessage: 'Se borran también sus subtareas. No se puede deshacer.',
    );

    return LifeQuestPage(
      title: 'Tareas',
      subtitle: 'La más urgente arriba.',
      numeral: '${missions.length}',
      numeralLabel: missions.length == 1 ? 'abierta' : 'abiertas',
      trailing: TextButton.icon(
        onPressed: onOpenProjects,
        icon: const Icon(Icons.folder_outlined, size: 20),
        label: const Text('Proyectos'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      children: [
        if (missions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No tienes tareas abiertas. Crea la primera abajo.',
              style: TextStyle(color: context.lq.muted, fontSize: 15),
            ),
          ),
        for (final (i, mission) in missions.indexed)
          SheetRow(
            current: i == 0,
            leading: SheetCheck(
              done: false,
              busy: state.busyMissionId == mission.id,
              label: 'Completar ${mission.title}',
              onTap: idle ? () => complete(mission.id) : null,
            ),
            time: MissionsFormat.time(mission.dueDate),
            title: mission.title,
            subtitle: [
              MissionsFormat.due(mission.dueDate, now),
              MissionsFormat.origin(mission),
              '${mission.xpReward} XP',
            ].join(' · '),
            trailing: menu(mission),
            action: i == 0
                ? SheetPill(label: 'Empezar foco', onTap: onStartFocus)
                : null,
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: idle ? () => _createMission(context, state) : null,
            icon: state.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(state.saving ? 'Creando tarea…' : 'Nueva tarea'),
          ),
        ),
      ],
    );
  }
}
