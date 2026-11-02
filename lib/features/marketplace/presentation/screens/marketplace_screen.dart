import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';
import 'package:proyecto_movil/features/marketplace/presentation/blocs/marketplace_bloc.dart';

/// Recompensas, protección de rachas y mejoras. Gastar nunca toca la XP ni el
/// nivel. Necesita un [MarketplaceBloc] por encima.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  static const _improvements = {
    'huerto': (
      Icons.favorite_outline,
      'Bienestar',
      '+1 de Constancia al día por nivel',
    ),
    'biblioteca': (
      Icons.auto_awesome_outlined,
      'Asistente',
      '+1 tarea guiada al día por nivel',
    ),
    'estandarte': (
      Icons.groups_outlined,
      'Más mentores',
      '+1 mentor por nivel',
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
    final protector = board.blackMarket
        .where((i) => i.code == 'pase_recuperacion')
        .firstOrNull;
    final hpFull = board.hpCurrent >= board.hpMax;

    return LifeQuestPage(
      title: 'Recompensas',
      icon: QIcons.coin,
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
                  label: 'Constancia',
                  value: '${board.hpCurrent}/${board.hpMax}',
                ),
              ),
            ],
          ),
        ),
        if (board.brokenStreaks.isNotEmpty) ...[
          const SizedBox(height: 14),
          const LifeQuestSectionHeading('RACHAS POR RECUPERAR'),
          const SizedBox(height: 7),
          for (final s in board.brokenStreaks)
            LifeQuestActionRow(
              icon: Icons.local_fire_department_outlined,
              title: '${s.name} · ${s.streak} días',
              subtitle:
                  'Puedes repararla hasta el '
                  '${LifeQuestDates.dayTime(s.deadline)}',
              actionLabel: board.passes > 0
                  ? 'Proteger racha'
                  : '${recover?.cost ?? '—'} Monedas',
              busy:
                  state.busyKey == s.habitId ||
                  state.busyKey == 'recuperar_racha',
              onAction: !idle
                  ? null
                  : board.passes > 0
                  ? () => bloc.add(RecoveryPassUsed(s.habitId))
                  : recover != null && recover.available
                  ? () => buy(
                      'Reparar racha',
                      recover.cost,
                      BlackMarketItemBought(recover.code, habitId: s.habitId),
                    )
                  : null,
            ),
        ],
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('RECUPERAR CONSTANCIA'),
        const SizedBox(height: 7),
        for (final i in board.items.where((i) => i.category == 'hotel'))
          _itemRow(
            i,
            state,
            enabled: idle && !hpFull,
            note: hpFull ? 'Tu Constancia está al máximo' : null,
            onBuy: () => buy(_itemName(i), i.cost, MarketItemBought(i.code)),
          ),
        if (protector != null) ...[
          const SizedBox(height: 14),
          const LifeQuestSectionHeading('PROTEGER RACHA'),
          const SizedBox(height: 7),
          _itemRow(
            protector,
            state,
            enabled: idle,
            note: 'Disponibles: ${board.passes}',
            onBuy: () => buy(
              'Protector de racha',
              protector.cost,
              BlackMarketItemBought(protector.code),
            ),
          ),
        ],
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('MEJORAS'),
        const SizedBox(height: 7),
        for (final b in board.refuge)
          LifeQuestActionRow(
            icon: _improvements[b.building]?.$1 ?? Icons.home_outlined,
            title:
                '${_improvements[b.building]?.$2 ?? b.building} · '
                'nivel ${b.level}/${b.maxLevel}',
            subtitle: _improvements[b.building]?.$3 ?? '',
            actionLabel: b.price == null ? 'Máximo' : '${b.price} Monedas',
            busy: state.busyKey == b.building,
            onAction: idle && b.price != null
                ? () => buy(
                    'Mejorar ${_improvements[b.building]?.$2 ?? b.building}',
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
      'hotel' => Icons.favorite_outline,
      'mercado_negro' => Icons.verified_outlined,
      _ => Icons.card_giftcard_outlined,
    },
    title: _itemName(item),
    subtitle: [
      if (item.category == 'hotel')
        'Recupera Constancia.'
      else if (item.code == 'pase_recuperacion')
        'Protege una racha durante un día fallido.'
      else
        ?item.description,
      if (!item.available) 'Disponible de nuevo pronto',
      ?note,
    ].join(' · '),
    actionLabel: '${item.cost} Monedas',
    busy: state.busyKey == item.code,
    onAction: enabled && item.available ? onBuy : null,
  );

  static String _itemName(MarketItem item) => switch (item.code) {
    'siesta' => 'Recuperación breve',
    'posada' => 'Recuperación amplia',
    'banquete' => 'Recuperación completa',
    'pase_recuperacion' => 'Protector de racha',
    _ => item.name,
  };
}
