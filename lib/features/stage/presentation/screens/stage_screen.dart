import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';
import 'package:proyecto_movil/features/stage/presentation/widgets/quick_add_sheets.dart';
import 'package:proyecto_movil/features/stage/presentation/widgets/stage_action_row.dart';
import 'package:proyecto_movil/features/stage/presentation/widgets/stage_project_card.dart';

/// Stage · P.A.R.A.: centro de mando de lectura sobre misiones, proyectos,
/// áreas (skills), recursos y archivo. No guarda datos propios.
/// Necesita un [StageBloc] por encima (lo provee el router).
class StageScreen extends StatelessWidget {
  const StageScreen({super.key, required this.onOpenMissions});

  /// Abre la lista completa de Misiones (y su alta).
  final VoidCallback onOpenMissions;

  @override
  Widget build(BuildContext context) => BlocConsumer<StageBloc, StageState>(
    listenWhen: (_, state) => state is StageSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as StageSuccess).message!),
    builder: (context, state) => switch (state) {
      StageInitial() || StageLoading() => const Center(
        child: CircularProgressIndicator(color: LifeQuestColors.deepGreen),
      ),
      StageFailure(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    context.read<StageBloc>().add(const StageRequested()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      StageSuccess() => RefreshIndicator(
        color: LifeQuestColors.deepGreen,
        onRefresh: () => _refresh(context.read<StageBloc>()),
        child: _content(context, state),
      ),
    },
  );

  static Future<void> _refresh(StageBloc bloc) {
    bloc.add(const StageRequested());
    return bloc.stream.firstWhere(
      (state) => state is! StageSuccess || !state.refreshing,
    );
  }

  Future<void> _quickAdd(BuildContext context, StageBoard board) async {
    final bloc = context.read<StageBloc>();
    Future<T?> sheet<T>(Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
    switch (await sheet<QuickAddKind>(const QuickAddSheet())) {
      case QuickAddKind.mission:
        onOpenMissions();
      case QuickAddKind.project:
        final project = await sheet<NewProject>(
          CreateProjectSheet(skills: board.skills, goals: board.goalLinks),
        );
        if (project != null) bloc.add(StageProjectCreated(project));
      case QuickAddKind.goal:
        final goal = await sheet<NewGoal>(
          CreateGoalSheet(skills: board.skills),
        );
        if (goal != null) bloc.add(StageGoalCreated(goal));
      case QuickAddKind.resource:
        final resource = await sheet<({String title, String url})>(
          const CreateResourceSheet(),
        );
        if (resource != null) {
          bloc.add(
            StageResourceCreated(title: resource.title, url: resource.url),
          );
        }
      case null:
        break;
    }
  }

  Widget _content(BuildContext context, StageSuccess state) {
    final bloc = context.read<StageBloc>();
    final board = state.board;
    final idle = !state.busy;
    return LifeQuestPage(
      title: 'Stage · P.A.R.A.',
      subtitle: 'Tu centro de mando, todo en un vistazo.',
      trailing: IconButton.filledTonal(
        tooltip: 'Añadir misión, proyecto, meta o recurso',
        onPressed: idle ? () => _quickAdd(context, board) : null,
        icon: state.busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
      ),
      children: [
        // RF-089: orden fijo urgent → high → medium → low → pending.
        LifeQuestSectionHeading(
          'DAILY HIGHLIGHT',
          action: 'Ver misiones (${board.highlightTotal})',
          onTap: onOpenMissions,
        ),
        const SizedBox(height: 7),
        if (board.highlight.isEmpty)
          _empty('Sin misiones abiertas. Añade una para empezar el día.'),
        for (final item in board.highlight)
          LifeQuestListRow(
            icon: switch (item.bucket) {
              StageBucket.urgent => Icons.bolt,
              StageBucket.pending => Icons.hourglass_empty_rounded,
              _ => Icons.flag_outlined,
            },
            title: item.title,
            subtitle: _bucketLabel(item.bucket),
          ),
        const SizedBox(height: 14),
        // Meta (Boss) → Proyecto → Misión: las metas van primero.
        LifeQuestSectionHeading(
          'METAS (JEFES)',
          action: '${board.goals.length} activas',
        ),
        const SizedBox(height: 7),
        if (board.goals.isEmpty)
          _empty(
            'Sin metas activas. Crea una con + y cada misión vinculada le restará vida al jefe.',
          ),
        for (final goal in board.goals)
          StageActionRow(
            icon: Icons.emoji_events_outlined,
            title: goal.title,
            subtitle: [
              '❤ ${goal.bossHp}/${goal.bossMaxHp} de vida del jefe',
              if (goal.dueDate case final due?)
                'vence ${due.day}/${due.month}/${due.year}',
              '${goal.projects} proyectos · ${goal.openTasks} misiones',
              ?goal.skillName,
            ].join(' · '),
            // Barra = vida que le queda al jefe.
            progress: goal.bossMaxHp == 0 ? 0 : goal.bossHp / goal.bossMaxHp,
            enabled: idle,
            actions: [
              (
                label: 'Archivar',
                onSelected: () => bloc.add(
                  StageItemArchived(kind: StageItemKind.goal, id: goal.id),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        LifeQuestSectionHeading(
          'PROYECTOS',
          action: '${board.projects.length} activos',
        ),
        const SizedBox(height: 7),
        if (board.projects.isEmpty)
          _empty(
            'Sin proyectos activos. Un proyecto agrupa misiones de semanas.',
          ),
        for (final project in board.projects)
          StageProjectCard(
            project: project,
            // Símbolo + texto: el color nunca va solo.
            urgencyLabel: _urgencyLabel(project.urgency),
            onAddMission: onOpenMissions,
            onCompleteTask: idle
                ? (id) => bloc.add(StageTaskCompleted(id))
                : null,
            onComplete: idle
                ? () => bloc.add(StageProjectCompleted(project.id))
                : null,
            onArchive: idle
                ? () => bloc.add(
                    StageItemArchived(
                      kind: StageItemKind.project,
                      id: project.id,
                    ),
                  )
                : null,
          ),
        const SizedBox(height: 14),
        LifeQuestSectionHeading(
          'ÁREAS (SKILLS)',
          action: '${board.areas.length}',
        ),
        const SizedBox(height: 7),
        if (board.areas.isEmpty)
          _empty('Crea tus áreas como skills desde tu Perfil.'),
        for (final area in board.areas)
          LifeQuestListRow(
            icon: Icons.category_outlined,
            title: area.name,
            subtitle:
                '${area.habits} hábitos · ${area.projects} proyectos · '
                '${area.openTasks} misiones abiertas',
            trailing: 'Nv ${area.level}',
          ),
        const SizedBox(height: 14),
        LifeQuestSectionHeading(
          'RECURSOS',
          action: '${board.resources.length}',
        ),
        const SizedBox(height: 7),
        if (board.resources.isEmpty)
          _empty('Guarda aquí enlaces útiles para tus áreas.'),
        for (final resource in board.resources)
          StageActionRow(
            icon: Icons.bookmark_border,
            title: resource.title,
            subtitle: resource.url,
            enabled: idle,
            actions: [
              (
                label: 'Copiar enlace',
                onSelected: () async {
                  await Clipboard.setData(ClipboardData(text: resource.url));
                  if (context.mounted) {
                    showLifeQuestMessage(context, 'Enlace copiado.');
                  }
                },
              ),
              (
                label: 'Archivar',
                onSelected: () => bloc.add(
                  StageItemArchived(
                    kind: StageItemKind.resource,
                    id: resource.id,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('ARCHIVO'),
        const SizedBox(height: 7),
        LifeQuestListRow(
          icon: Icons.inventory_2_outlined,
          title: board.archive.total == 0
              ? 'Tu archivo está vacío'
              : '${board.archive.total} elementos guardados',
          subtitle:
              '${board.archive.projects} proyectos · ${board.archive.goals} metas · '
              '${board.archive.resources} recursos',
        ),
      ],
    );
  }

  static Widget _empty(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      child: Text(
        text,
        style: const TextStyle(color: LifeQuestColors.muted, fontSize: 11),
      ),
    ),
  );

  static String _bucketLabel(StageBucket bucket) => switch (bucket) {
    StageBucket.urgent => '¡Hazlo ahora! · vence en menos de 24 h',
    StageBucket.high => 'Prioridad alta',
    StageBucket.medium => 'Prioridad media',
    StageBucket.low => 'Prioridad baja',
    StageBucket.pending => 'Delegada · pendiente',
  };

  static String _urgencyLabel(StageUrgency urgency) => switch (urgency) {
    StageUrgency.high => '🔴 Alta',
    StageUrgency.medium => '🟡 Media',
    StageUrgency.low => '🟢 Baja',
  };
}
