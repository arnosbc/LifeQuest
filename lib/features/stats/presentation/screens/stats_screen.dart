import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
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
      icon: QIcons.star,
      subtitle: 'Últimos 7 días frente a los 7 anteriores.',
      children: [
        _WeekRing(activeDays: b.xpByDay.where((d) => d.xp > 0).length),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text('Resumen', style: QText.title3(context.q.text)),
        ),
        const SizedBox(height: QSpace.m),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.bolt_rounded,
                label: _compareLabel('XP', b.xp, b.xpPrev),
                value: b.xp,
                tint: context.q.tint,
                ink: context.q.ink,
              ),
            ),
            const SizedBox(width: QSpace.m),
            Expanded(
              child: _SummaryTile(
                icon: Icons.check_rounded,
                label: _compareLabel('Tareas', b.missions, b.missionsPrev),
                value: b.missions,
                tint: context.q.riverTint,
                ink: context.q.riverInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: QSpace.m),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.schedule_rounded,
                label: _compareLabel(
                  'Min. foco',
                  b.focusMinutes,
                  b.focusMinutesPrev,
                ),
                value: b.focusMinutes,
                tint: context.q.mustardTint,
                ink: context.q.mustardInk,
              ),
            ),
            const SizedBox(width: QSpace.m),
            Expanded(
              child: _SummaryTile(
                icon: Icons.local_fire_department_outlined,
                label: 'Racha (récord ${b.recordStreak})',
                value: b.bestStreak,
                tint: context.q.coralTint,
                ink: context.q.coralInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const LifeQuestSectionHeading('EL ASISTENTE OBSERVA'),
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
            subtitle: 'Vincula tus tareas y hábitos a un área.',
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

  static String _compareLabel(String label, int value, int prev) {
    final diff = value - prev;
    return diff == 0 ? label : '$label ${diff > 0 ? '▲' : '▼'}${diff.abs()}';
  }
}

/// Anillo con los días de la semana en que se sumó XP.
class _WeekRing extends StatelessWidget {
  const _WeekRing({required this.activeDays});

  final int activeDays;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final pct = (activeDays * 100 / 7).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: q.tint,
        borderRadius: BorderRadius.circular(QRadius.card),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: activeDays / 7,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  color: q.accent,
                  backgroundColor: q.card,
                  semanticsLabel: 'Días activos esta semana',
                  semanticsValue: '$pct %',
                ),
                Center(
                  child: Text(
                    '$pct%',
                    style: QText.title2(q.text).copyWith(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeDays >= 4 ? '¡Vas muy bien!' : 'Cada día cuenta',
                  style: QText.title3(q.text),
                ),
                const SizedBox(height: QSpace.xs),
                Text(
                  'Sumaste XP en $activeDays de 7 días esta semana.',
                  style: QText.body(q.text2).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de color del Resumen: icono, etiqueta y cifra grande.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.ink,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(QRadius.block),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: q.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: ink),
                ),
                const SizedBox(width: QSpace.s),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: QText.body(q.text2).copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: QSpace.m),
            Text('$value', style: QText.title2(q.text)),
          ],
        ),
      ),
    );
  }
}
