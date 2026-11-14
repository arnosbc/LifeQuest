import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/challenges/domain/entities/challenges_board.dart';
import 'package:proyecto_movil/features/challenges/presentation/blocs/challenges_bloc.dart';

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre', //
];

/// Divisiones de la Liga, de la 0 a la 9.
const _divisions = [
  'Bronce', 'Plata', 'Oro', 'Zafiro', 'Rubí', 'Esmeralda', 'Amatista',
  'Perla', 'Obsidiana', 'Diamante', //
];

String _dailyTitle(DailyChallenge c) => switch (c.key) {
  'xp' => 'Gana ${c.target} XP',
  'tasks' => c.target == 1 ? 'Completa 1 tarea' : 'Completa ${c.target} tareas',
  'focus' =>
    c.target == 1
        ? 'Termina 1 ciclo en la Mazmorra'
        : 'Termina ${c.target} ciclos en la Mazmorra',
  _ => 'Desafío',
};

String _days(int n) => n == 1 ? '1 día' : '$n días';

/// Desafíos del día, del mes y Liga semanal (052). Necesita un
/// [ChallengesBloc] por encima.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  bool _league = false;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ChallengesBloc, ChallengesState>(
        listenWhen: (_, s) => s is ChallengesSuccess && s.message != null,
        listener: (context, s) =>
            showLifeQuestMessage(context, (s as ChallengesSuccess).message!),
        builder: (context, state) => switch (state) {
          ChallengesInitial() || ChallengesLoading() => Center(
            child: CircularProgressIndicator(color: context.q.ink),
          ),
          ChallengesFailure(:final message) => LifeQuestErrorView(
            message: message,
            onRetry: () =>
                context.read<ChallengesBloc>().add(const ChallengesRequested()),
          ),
          ChallengesSuccess() => RefreshIndicator(
            color: context.q.ink,
            onRefresh: () async {
              final bloc = context.read<ChallengesBloc>()
                ..add(const ChallengesRequested());
              await bloc.stream.firstWhere(
                (s) => s is! ChallengesSuccess || !s.refreshing,
              );
            },
            child: LifeQuestPage(
              title: _league ? 'Liga' : 'Desafíos',
              icon: QIcons.trophy,
              subtitle: _league
                  ? 'Gana XP esta semana y sube de división.'
                  : 'Metas pequeñas cada día, con cofre al final.',
              children: [
                QuestlySegmented<bool>(
                  segments: const [(false, 'Desafíos'), (true, 'Liga')],
                  selected: _league,
                  onChanged: (v) => setState(() => _league = v),
                ),
                const SizedBox(height: QSpace.l),
                if (_league)
                  ..._leagueView(context, state.board.league)
                else
                  ..._challengesView(context, state),
              ],
            ),
          ),
        },
      );

  List<Widget> _challengesView(BuildContext context, ChallengesSuccess state) {
    final bloc = context.read<ChallengesBloc>();
    final month = state.board.month;
    return [
      _MonthBanner(
        month: month,
        busy: state.claimingKey == 'month',
        onClaim: () => bloc.add(const ChallengeClaimed('month')),
      ),
      const SizedBox(height: QSpace.xl),
      Row(
        children: [
          const Expanded(child: LifeQuestSectionHeading('DESAFÍOS DEL DÍA')),
          Text('Se renuevan a medianoche', style: QText.meta(context.q.text3)),
        ],
      ),
      const SizedBox(height: QSpace.s),
      for (final c in state.board.daily)
        _DailyRow(
          challenge: c,
          busy: state.claimingKey == c.key,
          onClaim: () => bloc.add(ChallengeClaimed(c.key)),
        ),
    ];
  }

  List<Widget> _leagueView(BuildContext context, League league) {
    final q = context.q;
    final standings = league.standings;
    // 11 jugadores: top 3 sube; los 3 últimos bajan (salvo en la primera).
    final canDrop = league.division > 0;
    return [
      _LeagueHeader(league: league),
      if (league.lastResult case final r? when r != LeagueResult.stayed) ...[
        const SizedBox(height: QSpace.m),
        QuestlyCard(
          child: Text(
            r == LeagueResult.promoted
                ? '¡Subiste a la División ${_divisions[league.division]} la '
                      'semana pasada! 🎉'
                : 'Esta semana estás en ${_divisions[league.division]}. Cada '
                      'tarea cuenta para volver a subir.',
            style: QText.body(q.text),
          ),
        ),
      ],
      const SizedBox(height: QSpace.l),
      for (final (i, rival) in standings.indexed) ...[
        if (i == 3)
          _ZoneDivider(
            label: league.division < 9 ? 'ZONA DE ASCENSO' : 'CAMPEONES',
            icon: Icons.keyboard_double_arrow_up_rounded,
            color: q.ink,
          ),
        if (i == 8 && canDrop)
          _ZoneDivider(
            label: 'ZONA DE DESCENSO',
            icon: Icons.keyboard_double_arrow_down_rounded,
            color: q.coralInk,
          ),
        _StandingRow(
          rank: i + 1,
          name: rival?.name ?? 'Tú',
          xp: rival?.xp ?? league.xp,
          me: rival == null,
        ),
      ],
      const SizedBox(height: QSpace.l),
      Text(
        'Tus rivales son simulados y avanzan al ritmo de tu división: compites '
        'contra tu propia constancia, no contra otras personas.',
        style: QText.meta(q.text3),
        textAlign: TextAlign.center,
      ),
    ];
  }
}

/// Banner de color del Desafío del mes, como el de Duolingo.
class _MonthBanner extends StatelessWidget {
  const _MonthBanner({
    required this.month,
    required this.busy,
    required this.onClaim,
  });

  final MonthChallenge month;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final name = _months[DateTime.now().month - 1];
    return Container(
      padding: const EdgeInsets.all(QSpace.l),
      decoration: BoxDecoration(
        color: q.accent,
        borderRadius: BorderRadius.circular(QRadius.card),
        boxShadow: qSolidShadow(q.buttonShadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Desafío de $name', style: QText.title2(q.onAccent)),
                    const SizedBox(height: 2),
                    Text(
                      '⏱ ${_days(month.daysLeft).toUpperCase()}',
                      style: QText.label(q.onAccent),
                    ),
                  ],
                ),
              ),
              const MascotPose(pose: 'cofre', facesRight: false, size: 84),
            ],
          ),
          const SizedBox(height: QSpace.m),
          Container(
            padding: const EdgeInsets.all(QSpace.m),
            decoration: BoxDecoration(
              color: q.card,
              borderRadius: BorderRadius.circular(QRadius.block),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cumple ${month.target} desafíos del día',
                  style: QText.label(q.text),
                ),
                const SizedBox(height: QSpace.s),
                _ProgressBar(value: month.progress, target: month.target),
                if (month.ready || month.claimed) ...[
                  const SizedBox(height: QSpace.m),
                  QuestlyButton(
                    label: month.claimed
                        ? 'Desafío del mes cumplido'
                        : busy
                        ? 'Abriendo…'
                        : 'Abrir cofre · +${month.coins} Monedas',
                    onPressed: month.ready && !busy ? onClaim : null,
                  ),
                ] else ...[
                  const SizedBox(height: QSpace.xs),
                  Text(
                    'Premio: +${month.coins} Monedas',
                    style: QText.meta(q.text3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.challenge,
    required this.busy,
    required this.onClaim,
  });

  final DailyChallenge challenge;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final c = challenge;
    final title = _dailyTitle(c);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QSpace.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: QText.title3(q.text)),
                const SizedBox(height: QSpace.s),
                _ProgressBar(value: c.progress, target: c.target),
              ],
            ),
          ),
          const SizedBox(width: QSpace.m),
          _Chest(
            ready: c.ready,
            claimed: c.claimed,
            busy: busy,
            coins: c.coins,
            label: title,
            onTap: onClaim,
          ),
        ],
      ),
    );
  }
}

/// Cofre del desafío: gris cerrado, dorado y saltón cuando está listo, abierto
/// cuando ya se cobró.
class _Chest extends StatelessWidget {
  const _Chest({
    required this.ready,
    required this.claimed,
    required this.busy,
    required this.coins,
    required this.label,
    required this.onTap,
  });

  final bool ready;
  final bool claimed;
  final bool busy;
  final int coins;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final (bg, fg, icon) = claimed
        ? (q.track, q.text3, Icons.inventory_2_outlined)
        : ready
        ? (q.mustard, q.mustardInk, Icons.redeem_rounded)
        : (q.mustardTint, q.mustardInk, Icons.lock_outline_rounded);
    return QuestlyPressable(
      radius: QRadius.block,
      onTap: ready && !busy ? onTap : null,
      semanticsLabel: claimed
          ? '$label: cofre abierto'
          : ready
          ? '$label: abrir cofre, +$coins Monedas'
          : '$label: cofre cerrado, +$coins Monedas al cumplirlo',
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QRadius.block),
        boxShadow: ready ? qSolidShadow(q.mustardInk) : null,
      ),
      child: SizedBox.square(
        dimension: 56,
        child: busy
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 3, color: fg),
              )
            : Icon(icon, color: fg, size: 30),
      ),
    );
  }
}

/// Barra gruesa con «progreso / meta» encima, como en Duolingo.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.target});

  final int value;
  final int target;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final shown = value.clamp(0, target);
    final fraction = target == 0 ? 1.0 : shown / target;
    return Semantics(
      label: '$shown de $target',
      excludeSemantics: true,
      child: Container(
        height: 20,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: q.track,
          borderRadius: BorderRadius.circular(QRadius.action),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(color: q.accent),
            ),
            Center(
              child: Text(
                '$shown / $target',
                style: QText.meta(fraction >= .5 ? q.onAccent : q.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  const _LeagueHeader({required this.league});

  final League league;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      padding: const EdgeInsets.all(QSpace.l),
      decoration: BoxDecoration(
        color: q.riverTint,
        borderRadius: BorderRadius.circular(QRadius.card),
      ),
      child: Row(
        children: [
          const MascotPose(pose: 'corona', size: 84),
          const SizedBox(width: QSpace.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'División ${_divisions[league.division]}',
                  style: QText.title2(q.riverInk),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vas #${league.rank} · ${league.xp} XP · '
                  'termina en ${_days(league.daysLeft)}',
                  style: QText.label(q.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneDivider extends StatelessWidget {
  const _ZoneDivider({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: QSpace.m),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: QSpace.xs),
        Text(label, style: QText.label(color)),
        const SizedBox(width: QSpace.xs),
        Icon(icon, color: color, size: 20),
      ],
    ),
  );
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rank,
    required this.name,
    required this.xp,
    required this.me,
  });

  final int rank;
  final String name;
  final int xp;
  final bool me;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final ink = rank <= 3 ? q.ink : q.text2;
    return Semantics(
      label: 'Puesto $rank, $name, $xp XP',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: QSpace.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.m,
          vertical: QSpace.s,
        ),
        decoration: BoxDecoration(
          color: me ? q.tint : null,
          borderRadius: BorderRadius.circular(QRadius.block),
          border: me ? Border.all(color: q.accent, width: 2) : null,
        ),
        child: Row(
          children: [
            SizedBox(width: 28, child: Text('$rank', style: QText.title3(ink))),
            CircleAvatar(
              radius: 20,
              backgroundColor: me ? q.accent : q.track,
              child: Text(
                name.characters.first.toUpperCase(),
                style: QText.title3(me ? q.onAccent : q.text),
              ),
            ),
            const SizedBox(width: QSpace.m),
            Expanded(
              child: Text(
                name,
                style: QText.label(q.text),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('$xp XP', style: QText.label(me ? q.ink : q.text2)),
          ],
        ),
      ),
    );
  }
}
