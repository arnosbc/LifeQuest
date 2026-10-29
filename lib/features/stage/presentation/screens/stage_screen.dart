import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';
import 'package:proyecto_movil/features/stage/presentation/widgets/create_resource_sheet.dart';
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
    listenWhen: (_, state) =>
        state is StageSuccess &&
        (state.message != null || state.openUrl != null),
    listener: (context, state) {
      final s = state as StageSuccess;
      if (s.message case final message?) showLifeQuestMessage(context, message);
      if (s.openUrl case final url?) _open(context, url);
    },
    builder: (context, state) => switch (state) {
      StageInitial() || StageLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
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
        color: context.lq.deepGreen,
        onRefresh: () => _refresh(context.read<StageBloc>()),
        child: _content(context, state),
      ),
    },
  );

  /// Abre un enlace o un documento (enlace temporal) fuera de la app.
  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showLifeQuestMessage(
        context,
        'No pudimos abrirlo. Revisa que tengas una app para este tipo de archivo.',
      );
    }
  }

  /// Muestra una nota guardada, con el texto seleccionable para copiarlo.
  static Future<void> _showNote(BuildContext context, StageResource note) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            color: context.lq.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        note.title,
                        style: TextStyle(
                          color: context.lq.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.lq.ink),
                  ),
                ],
              ),
              if (note.links.isNotEmpty)
                Text(
                  note.links.join(' · '),
                  style: TextStyle(color: context.lq.muted, fontSize: 12),
                ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 12),
                  child: SelectableText(
                    note.content ?? '',
                    style: TextStyle(
                      color: context.lq.ink,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        final goal = await sheet<SmartGoal>(
          SmartGoalSheet(
            skills: [
              for (final s in board.skills) SkillChoice(id: s.id, name: s.name),
            ],
          ),
        );
        if (goal != null) {
          bloc.add(
            StageGoalCreated(
              NewGoal(
                title: goal.title,
                specific: goal.specific,
                measurable: goal.measurable,
                achievable: goal.achievable,
                relevant: goal.relevant,
                dueDate: goal.dueDate,
                timebound: goal.timebound,
                skillId: goal.skillId,
              ),
            ),
          );
        }
      case QuickAddKind.resource:
        final resource = await sheet<NewResource>(
          CreateResourceSheet(
            projects: [
              for (final p in board.projects)
                StageLink(id: p.id, name: p.title),
            ],
            goals: board.goalLinks,
            skills: board.skills,
          ),
        );
        if (resource != null) bloc.add(StageResourceCreated(resource));
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
          _empty(
            context,
            'Sin misiones abiertas. Añade una para empezar el día.',
          ),
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
            context,
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
            context,
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
          _empty(context, 'Crea tus áreas como skills desde tu Perfil.'),
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
          _empty(
            context,
            'Guarda aquí enlaces, notas y documentos para tus proyectos, '
            'metas y áreas.',
          ),
        for (final resource in board.resources)
          StageActionRow(
            icon: switch (resource.kind) {
              ResourceKind.link => Icons.link,
              ResourceKind.note => Icons.notes,
              ResourceKind.document => Icons.description_outlined,
            },
            title: resource.title,
            subtitle: [
              switch (resource.kind) {
                ResourceKind.link => resource.url ?? 'Enlace',
                ResourceKind.note => 'Nota',
                ResourceKind.document => 'Documento',
              },
              ...resource.links,
            ].join(' · '),
            enabled: idle,
            actions: [
              switch (resource.kind) {
                ResourceKind.link => (
                  label: 'Abrir enlace',
                  onSelected: () => _open(context, resource.url ?? ''),
                ),
                ResourceKind.note => (
                  label: 'Ver nota',
                  onSelected: () => _showNote(context, resource),
                ),
                ResourceKind.document => (
                  label: 'Abrir documento',
                  onSelected: () => bloc.add(StageResourceOpened(resource)),
                ),
              },
              if (resource.kind == ResourceKind.link)
                (
                  label: 'Copiar enlace',
                  onSelected: () async {
                    await Clipboard.setData(
                      ClipboardData(text: resource.url ?? ''),
                    );
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

  static Widget _empty(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      child: Text(
        text,
        style: TextStyle(color: context.lq.muted, fontSize: 11),
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
