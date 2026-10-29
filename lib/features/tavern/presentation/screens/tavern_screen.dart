import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/presentation/blocs/tavern_bloc.dart';
import 'package:proyecto_movil/features/tavern/presentation/widgets/create_npc_sheet.dart';
import 'package:proyecto_movil/features/tavern/presentation/widgets/npc_documents_sheet.dart';
import 'package:proyecto_movil/features/tavern/presentation/widgets/npc_mission_guide_sheet.dart';

/// Taverna: NPCs que piden misiones reales. Necesita un [TavernBloc] encima.
class TavernScreen extends StatelessWidget {
  const TavernScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<TavernBloc, TavernState>(
    listenWhen: (_, s) => s is TavernSuccess && s.message != null,
    listener: (context, s) =>
        showLifeQuestMessage(context, (s as TavernSuccess).message!),
    builder: (context, state) => switch (state) {
      TavernInitial() || TavernLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      TavernFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<TavernBloc>().add(const TavernRequested()),
      ),
      TavernSuccess() => RefreshIndicator(
        color: context.lq.deepGreen,
        onRefresh: () async {
          final bloc = context.read<TavernBloc>()..add(const TavernRequested());
          await bloc.stream.firstWhere(
            (s) => s is! TavernSuccess || !s.refreshing,
          );
        },
        child: _content(context, state),
      ),
    },
  );

  Widget _content(BuildContext context, TavernSuccess state) {
    final board = state.board;
    final bloc = context.read<TavernBloc>();
    final idle = state.busyKey == null;
    final now = DateTime.now();
    Widget menu(Npc npc) => LifeQuestItemMenu(
      name: npc.name,
      enabled: idle,
      maxLength: 60,
      onRename: (name) => bloc.add(NpcRenamed(npc.id, name)),
      onDelete: () => bloc.add(NpcDeleted(npc.id)),
      deleteMessage: 'Sus misiones se conservan como misiones sueltas.',
    );

    Future<void> ask(Npc npc) async {
      final free = npc.isFree(now);
      if (!free &&
          !await confirmLifeQuest(
            context,
            title: 'Pedir misión ya',
            message:
                '${npc.name} tendrá una misión gratis a las '
                '${LifeQuestDates.dayTime(npc.freeAt!)}. '
                '¿Pedirla ahora por ${board.instantCost} Monedas?',
            confirmLabel: 'Pedir ahora',
          )) {
        return;
      }
      bloc.add(NpcMissionRequested(npc));
    }

    Future<void> create() async {
      final npc = await showModalBottomSheet<NewNpc>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CreateNpcSheet(skills: board.skills),
      );
      if (npc != null) bloc.add(NpcCreated(npc));
    }

    Future<void> documents(Npc npc) async {
      final action = await showModalBottomSheet<NpcDocumentsAction>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NpcDocumentsSheet(npc: npc),
      );
      if (!context.mounted) return;
      switch (action) {
        case AttachNpcDocument(:final document):
          showLifeQuestMessage(
            context,
            'RPGenie está leyendo «${document.title}». Puede tardar un minuto.',
          );
          bloc.add(NpcDocumentAdded(document));
        case RemoveNpcDocumentAction(document: final doc):
          if (await confirmLifeQuest(
                context,
                title: 'Quitar documento',
                message:
                    '${npc.name} dejará de usar «${doc.title}» para sus misiones.',
                confirmLabel: 'Quitar',
              ) &&
              context.mounted) {
            bloc.add(NpcDocumentRemoved(npcId: npc.id, documentId: doc.id));
          }
        case null:
          break;
      }
    }

    return LifeQuestPage(
      title: 'Taverna',
      subtitle: 'Los personajes de tu reino tienen encargos para ti.',
      children: [
        LifeQuestSectionHeading(
          'NPCs · ${board.npcs.length}/${board.npcLimit}',
        ),
        const SizedBox(height: 7),
        if (board.npcs.isEmpty)
          const LifeQuestListRow(
            icon: Icons.sports_bar_outlined,
            title: 'La Taverna está tranquila',
            subtitle:
                'Invita a tu primer NPC: te pedirá misiones de una de tus skills.',
          ),
        for (final npc in board.npcs) ...[
          if (npc.openMission case final mission?) ...[
            LifeQuestActionRow(
              icon: Icons.person_outline,
              title: '${npc.name} · ${npc.skillName}',
              subtitle: 'Misión: ${mission.title} · +${mission.xpReward} XP',
              actionLabel: 'Cumplir',
              busy: state.busyKey == npc.id,
              menu: menu(npc),
              onAction: idle
                  ? () => bloc.add(
                      NpcMissionCompleted(npcId: npc.id, taskId: mission.id),
                    )
                  : null,
            ),
          ] else
            LifeQuestActionRow(
              icon: Icons.person_outline,
              title: '${npc.name} · ${npc.skillName}',
              subtitle: [
                npc.nobleMission ?? _frequency(npc.frequency),
                if (npc.completed > 0) '${npc.completed} cumplidas',
              ].join(' · '),
              actionLabel: npc.isFree(now)
                  ? 'Pedir misión'
                  : '${board.instantCost} 🪙',
              busy: state.busyKey == npc.id,
              menu: menu(npc),
              onAction: idle ? () => ask(npc) : null,
            ),
          Wrap(
            children: [
              if (npc.openMission case final mission?
                  when mission.description != null)
                _link(
                  context,
                  icon: Icons.menu_book_outlined,
                  label: 'Ver guía: pasos y pistas',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => NpcMissionGuideSheet(
                      npcName: npc.name,
                      mission: mission,
                    ),
                  ),
                ),
              _link(
                context,
                icon: Icons.description_outlined,
                label: npc.documents.isEmpty
                    ? 'Adjuntar plan o documento'
                    : 'Documentos (${npc.documents.length})',
                onPressed: idle ? () => documents(npc) : null,
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (board.skills.isEmpty)
          Text(
            'Crea una skill en tu Perfil para invitar NPCs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.lq.muted, fontSize: 12),
          )
        else
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: idle && !board.full ? create : null,
              icon: state.busyKey == 'new_npc'
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                board.full
                    ? 'Taverna llena · mejora el Estandarte'
                    : 'Nuevo NPC',
              ),
            ),
          ),
      ],
    );
  }

  /// Enlace de texto bajo la fila del NPC (guía, documentos).
  static Widget _link(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: TextButton.styleFrom(
      foregroundColor: context.lq.deepGreen,
      minimumSize: const Size(48, 44),
    ),
  );

  static String _frequency(NpcFrequency f) => switch (f) {
    NpcFrequency.daily => 'Te visita a diario',
    NpcFrequency.weekly => 'Te visita cada semana',
    NpcFrequency.monthly => 'Te visita cada mes',
  };
}
