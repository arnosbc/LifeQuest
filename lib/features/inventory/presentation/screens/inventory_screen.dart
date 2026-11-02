import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/inventory/domain/entities/inventory_board.dart';
import 'package:proyecto_movil/features/inventory/presentation/blocs/inventory_bloc.dart';

/// Logros y objetos disponibles. Necesita un
/// [InventoryBloc] por encima.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.onOpenMarketplace});

  /// Los objetos se consultan en Recompensas.
  final VoidCallback onOpenMarketplace;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _showAchievements = false;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<InventoryBloc, InventoryState>(
        listenWhen: (_, s) => s is InventorySuccess && s.message != null,
        listener: (context, s) =>
            showLifeQuestMessage(context, (s as InventorySuccess).message!),
        builder: (context, state) => switch (state) {
          InventoryInitial() || InventoryLoading() => Center(
            child: CircularProgressIndicator(color: context.lq.deepGreen),
          ),
          InventoryFailure(:final message) => LifeQuestErrorView(
            message: message,
            onRetry: () =>
                context.read<InventoryBloc>().add(const InventoryRequested()),
          ),
          InventorySuccess(:final board) => RefreshIndicator(
            color: context.lq.deepGreen,
            onRefresh: () async {
              final bloc = context.read<InventoryBloc>()
                ..add(const InventoryRequested());
              await bloc.stream.firstWhere(
                (s) => s is! InventorySuccess || !s.refreshing,
              );
            },
            child: LifeQuestPage(
              title: 'Logros',
              icon: QIcons.trophy,
              subtitle: 'Tus insignias y objetos disponibles.',
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Objetos')),
                    ButtonSegment(value: true, label: Text('Logros')),
                  ],
                  selected: {_showAchievements},
                  onSelectionChanged: (s) =>
                      setState(() => _showAchievements = s.first),
                ),
                const SizedBox(height: 14),
                if (_showAchievements)
                  ..._achievements(board)
                else
                  ..._items(board),
              ],
            ),
          ),
        },
      );

  List<Widget> _items(InventoryBoard b) => [
    if (b.passes > 0)
      LifeQuestListRow(
        icon: Icons.verified_outlined,
        title: 'Protector de racha',
        subtitle: 'Disponible para proteger una racha.',
        trailing: '×${b.passes}',
      )
    else
      const LifeQuestListRow(
        icon: Icons.verified_outlined,
        title: 'No tienes protectores de racha',
        subtitle: 'Puedes conseguir uno en Recompensas.',
      ),
    const SizedBox(height: 8),
    SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: widget.onOpenMarketplace,
        icon: const Icon(Icons.storefront_outlined),
        label: const Text('Ver Recompensas'),
      ),
    ),
  ];

  List<Widget> _achievements(InventoryBoard b) => [
    const LifeQuestSectionHeading('INSIGNIAS'),
    const SizedBox(height: 7),
    if (b.titles.isEmpty)
      const LifeQuestListRow(
        icon: Icons.workspace_premium_outlined,
        title: 'Aún no tienes insignias',
        subtitle: 'Se consiguen al completar logros y subir de nivel.',
      ),
    for (final t in b.titles)
      LifeQuestListRow(
        icon: Icons.workspace_premium_outlined,
        title: t.name,
        subtitle: [
          ?t.description,
          if (t.earnedAt != null)
            'Ganado el ${LifeQuestDates.day(t.earnedAt!)}',
        ].join(' · '),
      ),
    if (b.achievements.isNotEmpty) ...[
      const SizedBox(height: 14),
      LifeQuestSectionHeading(
        'LOGROS · ${b.achievements.where((a) => a.unlockedAt != null).length}'
        '/${b.achievements.length}',
      ),
      const SizedBox(height: 7),
      for (final a in b.achievements)
        LifeQuestListRow(
          icon: a.unlockedAt != null
              ? Icons.emoji_events_outlined
              : Icons.lock_outline,
          title: a.name,
          subtitle: [
            ?a.description,
            if (a.unlockedAt != null)
              'Desbloqueado el ${LifeQuestDates.day(a.unlockedAt!)}'
            else
              'Por desbloquear',
          ].join(' · '),
          trailing: a.rewardCoins > 0 ? '${a.rewardCoins} Monedas' : null,
        ),
    ],
  ];
}
