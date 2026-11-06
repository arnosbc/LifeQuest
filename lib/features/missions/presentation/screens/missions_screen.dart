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

  /// Abre Foco, con la tarea ya en la mochila si se indica.
  final void Function([String? taskId]) onStartFocus;

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

    final current = missions.isEmpty ? null : missions.first.id;
    Widget row(Mission mission) => SheetRow(
      current: mission.id == current,
      leading: SheetCheck(
        done: false,
        busy: state.busyMissionId == mission.id,
        label: 'Completar ${mission.title}',
        onTap: idle ? () => complete(mission.id) : null,
      ),
      time: MissionsFormat.time(mission.scheduledAt ?? mission.dueDate),
      title: mission.title,
      subtitle: [
        MissionsFormat.due(mission.dueDate, now),
        MissionsFormat.origin(mission),
        ?MissionsFormat.repeat(mission.repeatRule),
        ?MissionsFormat.focus(mission),
        '${mission.xpReward} XP',
      ].join(' · '),
      trailing: menu(mission),
      action: mission.id == current
          ? SheetPill(
              label: 'Empezar foco',
              onTap: () => onStartFocus(mission.id),
            )
          : null,
    );
    final groups = _group(missions, now);

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
          LifeQuestEmptyState(
            illustration: LifeQuestIllustration.blank,
            title: 'No tienes tareas abiertas',
            message: 'Anota lo siguiente que quieres hacer y empieza por ahí.',
            actionLabel: 'Nueva tarea',
            onAction: idle ? () => _createMission(context, state) : null,
          )
        else ...[
          _Summary(groups: groups, missions: missions),
          for (final (label, group) in groups)
            if (group.isNotEmpty) ...[
              const SizedBox(height: 20),
              LifeQuestSectionHeading('$label · ${group.length}'),
              for (final mission in group) row(mission),
            ],
        ],
        if (missions.isNotEmpty) ...[
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
      ],
    );
  }

  /// Hoy (incluye lo que ya venció), próximas y sin fecha; conserva el orden
  /// de urgencia que trae el servidor dentro de cada grupo.
  static List<(String, List<Mission>)> _group(
    List<Mission> missions,
    DateTime now,
  ) {
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    bool today(Mission m) =>
        m.dueDate != null && m.dueDate!.isBefore(endOfToday);
    return [
      (
        'Hoy',
        [
          for (final m in missions)
            if (today(m)) m,
        ],
      ),
      (
        'Próximas',
        [
          for (final m in missions)
            if (m.dueDate != null && !today(m)) m,
        ],
      ),
      (
        'Sin fecha',
        [
          for (final m in missions)
            if (m.dueDate == null) m,
        ],
      ),
    ];
  }
}

/// Bloque de resumen: cuántas tocan hoy, cuántas después y la XP en juego.
class _Summary extends StatelessWidget {
  const _Summary({required this.groups, required this.missions});

  final List<(String, List<Mission>)> groups;
  final List<Mission> missions;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    color: context.q.tint,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: LifeQuestStat(
            value: '${groups[0].$2.length}',
            label: 'Para hoy',
          ),
        ),
        Expanded(
          child: LifeQuestStat(
            value: '${groups[1].$2.length + groups[2].$2.length}',
            label: 'Después',
          ),
        ),
        Expanded(
          child: LifeQuestStat(
            value: '${missions.fold(0, (sum, m) => sum + m.xpReward)}',
            label: 'XP en juego',
          ),
        ),
      ],
    ),
  );
}
