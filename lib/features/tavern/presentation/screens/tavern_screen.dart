import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/presentation/blocs/tavern_bloc.dart';
import 'package:proyecto_movil/features/tavern/presentation/widgets/create_npc_sheet.dart';

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
      if (!context.mounted) return;
      final title = await askLifeQuestText(
        context,
        title: '¿Qué te propone ${npc.name}?',
        label: npc.nobleMission == null
            ? 'Misión'
            : 'Misión para: ${npc.nobleMission}',
        confirmLabel: 'Aceptar misión',
      );
      if (title != null) {
        bloc.add(NpcMissionAccepted(npcId: npc.id, title: title));
      }
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
          if (npc.openMission case final mission?)
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
            )
          else
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

  static String _frequency(NpcFrequency f) => switch (f) {
    NpcFrequency.daily => 'Te visita a diario',
    NpcFrequency.weekly => 'Te visita cada semana',
    NpcFrequency.monthly => 'Te visita cada mes',
  };
}
