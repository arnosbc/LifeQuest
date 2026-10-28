import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';
import 'package:proyecto_movil/features/marketplace/presentation/blocs/marketplace_bloc.dart';

/// Marketplace: Hotel, Mercado, Mercado negro y Refugio. Gastar nunca toca
/// la XP ni el nivel. Necesita un [MarketplaceBloc] por encima.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  static const _refuge = {
    'huerto': (Icons.grass, 'Huerto', '+1 de vida al día por nivel'),
    'biblioteca': (
      Icons.menu_book_outlined,
      'Biblioteca de RPGenie',
      '+1 misión ligera al día por nivel',
    ),
    'estandarte': (
      Icons.flag_outlined,
      'Estandarte del gremio',
      '+1 NPC en la Taverna por nivel',
    ),
  };

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MarketplaceBloc, MarketplaceState>(
        listenWhen: (_, s) => s is MarketplaceSuccess && s.message != null,
        listener: (context, s) =>
            showLifeQuestMessage(context, (s as MarketplaceSuccess).message!),
        builder: (context, state) => switch (state) {
          MarketplaceInitial() || MarketplaceLoading() => Center(
            child: CircularProgressIndicator(color: context.lq.deepGreen),
          ),
          MarketplaceFailure(:final message) => LifeQuestErrorView(
            message: message,
            onRetry: () => context.read<MarketplaceBloc>().add(
              const MarketplaceRequested(),
            ),
          ),
          MarketplaceSuccess() => RefreshIndicator(
            color: context.lq.deepGreen,
            onRefresh: () async {
              final bloc = context.read<MarketplaceBloc>()
                ..add(const MarketplaceRequested());
              await bloc.stream.firstWhere(
                (s) => s is! MarketplaceSuccess || !s.refreshing,
              );
            },
            child: _content(context, state),
          ),
        },
      );

  Widget _content(BuildContext context, MarketplaceSuccess state) {
    final board = state.board;
    final bloc = context.read<MarketplaceBloc>();
    final idle = state.busyKey == null;

    Future<void> buy(String name, int cost, MarketplaceEvent event) async {
      if (await confirmLifeQuest(
        context,
        title: name,
        message: '¿Canjear por $cost Monedas? Tu XP y tu nivel no cambian.',
        confirmLabel: 'Canjear',
      )) {
        bloc.add(event);
      }
    }

    final recover = board.blackMarket
        .where((i) => i.code == 'recuperar_racha')
        .firstOrNull;
    final hpFull = board.hpCurrent >= board.hpMax;

    return LifeQuestPage(
      title: 'Marketplace',
      subtitle: 'Disfruta lo que has ganado. Tu avance no se toca.',
      children: [
        LifeQuestSurface(
          color: context.lq.softGreen,
          child: Row(
            children: [
              Expanded(
                child: LifeQuestStat(label: 'Monedas', value: '${board.coins}'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: LifeQuestStat(
                  label: 'Tesoro',
                  value: '${board.treasury}',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: LifeQuestStat(
                  label: 'Vida',
                  value: '${board.hpCurrent}/${board.hpMax}',
                ),
              ),
            ],
          ),
        ),
        if (board.brokenStreaks.isNotEmpty) ...[
          const SizedBox(height: 14),
          const LifeQuestSectionHeading('RACHAS POR SALVAR'),
          const SizedBox(height: 7),
          for (final s in board.brokenStreaks)
            LifeQuestActionRow(
              icon: Icons.local_fire_department_outlined,
              title: '${s.name} · ${s.streak} días',
              subtitle:
                  'Puedes salvarla hasta el '
                  '${LifeQuestDates.dayTime(s.deadline)}',
              actionLabel: board.passes > 0
                  ? 'Usar Pase'
                  : '${recover?.cost ?? '—'} 🪙',
              busy:
                  state.busyKey == s.habitId ||
                  state.busyKey == 'recuperar_racha',
              onAction: !idle
                  ? null
                  : board.passes > 0
                  ? () => bloc.add(RecoveryPassUsed(s.habitId))
                  : recover != null && recover.available
                  ? () => buy(
                      'Recuperar racha',
                      recover.cost,
                      BlackMarketItemBought(recover.code, habitId: s.habitId),
                    )
                  : null,
            ),
        ],
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('HOTEL'),
        const SizedBox(height: 7),
        for (final i in board.items.where((i) => i.category == 'hotel'))
          _itemRow(
            i,
            state,
            enabled: idle && !hpFull,
            note: hpFull ? 'Tu vida está completa' : null,
            onBuy: () => buy(i.name, i.cost, MarketItemBought(i.code)),
          ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('MERCADO'),
        const SizedBox(height: 7),
        for (final i in board.items.where((i) => i.category == 'mercado'))
          _itemRow(
            i,
            state,
            enabled: idle,
            onBuy: () => buy(i.name, i.cost, MarketItemBought(i.code)),
          ),
        if (board.elixirActive)
          const LifeQuestListRow(
            icon: Icons.bolt,
            title: 'Elixir activo',
            subtitle: 'Tu próxima Mazmorra dará ×1,5 de XP.',
          )
        else if (board.elixirsStored > 0)
          LifeQuestActionRow(
            icon: Icons.science_outlined,
            title: 'Elixir guardado',
            subtitle: 'Actívalo antes de entrar a la Mazmorra.',
            actionLabel: 'Activar',
            busy: state.busyKey == 'elixir_activate',
            onAction: idle ? () => bloc.add(const ElixirActivated()) : null,
          ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('MERCADO NEGRO'),
        const SizedBox(height: 7),
        for (final i in board.blackMarket)
          if (i.code == 'pase_recuperacion')
            _itemRow(
              i,
              state,
              enabled: idle,
              note: 'Guardados: ${board.passes} · 1 al mes',
              onBuy: () => buy(i.name, i.cost, BlackMarketItemBought(i.code)),
            )
          else
            LifeQuestListRow(
              icon: Icons.restore,
              title: i.name,
              subtitle: i.available
                  ? 'Úsalo cuando una racha se rompa (48 h) · 1 al mes'
                  : 'Ya lo usaste este mes',
              trailing: '${i.cost} 🪙',
            ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('REFUGIO'),
        const SizedBox(height: 7),
        for (final b in board.refuge)
          LifeQuestActionRow(
            icon: _refuge[b.building]?.$1 ?? Icons.home_outlined,
            title:
                '${_refuge[b.building]?.$2 ?? b.building} · '
                'nivel ${b.level}/${b.maxLevel}',
            subtitle: _refuge[b.building]?.$3 ?? '',
            actionLabel: b.price == null ? 'Máximo' : '${b.price} 🪙',
            busy: state.busyKey == b.building,
            onAction: idle && b.price != null
                ? () => buy(
                    'Mejorar ${_refuge[b.building]?.$2 ?? b.building}',
                    b.price!,
                    RefugeUpgraded(b.building),
                  )
                : null,
          ),
      ],
    );
  }

  static Widget _itemRow(
    MarketItem item,
    MarketplaceSuccess state, {
    required bool enabled,
    required VoidCallback onBuy,
    String? note,
  }) => LifeQuestActionRow(
    icon: switch (item.category) {
      'hotel' => Icons.hotel_outlined,
      'mercado_negro' => Icons.confirmation_number_outlined,
      _ => Icons.science_outlined,
    },
    title: item.name,
    subtitle: [
      ?item.description,
      if (!item.available) 'Disponible de nuevo pronto',
      ?note,
    ].join(' · '),
    actionLabel: '${item.cost} 🪙',
    busy: state.busyKey == item.code,
    onAction: enabled && item.available ? onBuy : null,
  );
}
