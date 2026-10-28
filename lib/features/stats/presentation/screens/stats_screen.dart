import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/stats/domain/entities/stats_board.dart';
import 'package:proyecto_movil/features/stats/presentation/blocs/stats_bloc.dart';

/// Estadísticas: la semana frente a la anterior. Pantalla de lectura;
/// necesita un [StatsBloc] por encima.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<StatsBloc, StatsState>(
    listenWhen: (_, s) => s is StatsSuccess && s.message != null,
    listener: (context, s) =>
        showLifeQuestMessage(context, (s as StatsSuccess).message!),
    builder: (context, state) => switch (state) {
      StatsInitial() || StatsLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      StatsFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<StatsBloc>().add(const StatsRequested()),
      ),
      StatsSuccess(:final board) => RefreshIndicator(
        color: context.lq.deepGreen,
        onRefresh: () async {
          final bloc = context.read<StatsBloc>()..add(const StatsRequested());
          await bloc.stream.firstWhere(
            (s) => s is! StatsSuccess || !s.refreshing,
          );
        },
        child: _content(context, board),
      ),
    },
  );

  Widget _content(BuildContext context, StatsBoard b) {
    final maxDay = b.xpByDay.fold<int>(1, (m, d) => math.max(m, d.xp));
    final maxSkill = b.xpBySkill.fold<int>(1, (m, s) => math.max(m, s.xp));
    return LifeQuestPage(
      title: 'Estadísticas',
      subtitle: 'Últimos 7 días frente a los 7 anteriores.',
      children: [
        Row(
          children: [
            Expanded(child: _compare('XP', b.xp, b.xpPrev)),
            const SizedBox(width: 6),
            Expanded(child: _compare('Misiones', b.missions, b.missionsPrev)),
            const SizedBox(width: 6),
            Expanded(
              child: _compare('Min. foco', b.focusMinutes, b.focusMinutesPrev),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: LifeQuestStat(
                value: '${b.bestStreak}',
                label: 'Racha (récord ${b.recordStreak})',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const LifeQuestSectionHeading('RPGENIE OBSERVA'),
        const SizedBox(height: 7),
        for (final note in b.observations)
          LifeQuestListRow(icon: Icons.auto_awesome, title: note, subtitle: ''),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('XP POR DÍA'),
        const SizedBox(height: 7),
        LifeQuestSurface(
          child: SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in b.xpByDay)
                  Expanded(
                    child: Semantics(
                      label: '${LifeQuestDates.day(d.day)}: ${d.xp} XP',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${d.xp}',
                            style: TextStyle(
                              color: context.lq.muted,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 80 * d.xp / maxDay,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: context.lq.deepGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            const [
                              'L',
                              'M',
                              'X',
                              'J',
                              'V',
                              'S',
                              'D',
                            ][d.day.weekday - 1],
                            style: TextStyle(
                              color: context.lq.ink,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('XP POR ÁREA'),
        const SizedBox(height: 7),
        if (b.xpBySkill.isEmpty)
          const LifeQuestListRow(
            icon: Icons.category_outlined,
            title: 'Sin XP por Área esta semana',
            subtitle: 'Vincula tus misiones y hábitos a una skill.',
          ),
        for (final s in b.xpBySkill)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.name} · ${s.xp} XP',
                  style: TextStyle(color: context.lq.ink, fontSize: 12),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.xp / maxSkill,
                    minHeight: 8,
                    color: context.lq.deepGreen,
                    backgroundColor: context.lq.line,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('HÁBITOS MÁS CONSTANTES · 30 DÍAS'),
        const SizedBox(height: 7),
        if (b.topHabits.isEmpty)
          const LifeQuestListRow(
            icon: Icons.monitor_heart_outlined,
            title: 'Aún no hay hábitos registrados',
            subtitle: 'Cada hábito cumplido aparecerá aquí.',
          ),
        for (final h in b.topHabits)
          LifeQuestListRow(
            icon: Icons.local_fire_department_outlined,
            title: h.name,
            subtitle: 'Racha actual: ${h.streak} días',
            trailing: '${h.days}/30',
          ),
      ],
    );
  }

  static Widget _compare(String label, int value, int prev) {
    final diff = value - prev;
    return LifeQuestStat(
      value: '$value',
      label: diff == 0 ? label : '$label ${diff > 0 ? '▲' : '▼'}${diff.abs()}',
    );
  }
}
