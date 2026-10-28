import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';
import 'package:proyecto_movil/features/journal/presentation/blocs/journal_bloc.dart';

/// Diario: resumen semanal + Bitácora filtrable (CLAUDE.md §13). Pantalla de
/// lectura; necesita un [JournalBloc] por encima.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _filters = {
    'Todo': <JournalSource>{},
    'Tareas': {JournalSource.task, JournalSource.npc, JournalSource.project},
    'Hábitos': {JournalSource.habit},
    'Mazmorras': {JournalSource.dungeon},
    'Metas': {JournalSource.goal},
  };

  String _filter = 'Todo';

  @override
  Widget build(BuildContext context) => BlocConsumer<JournalBloc, JournalState>(
    listenWhen: (_, s) => s is JournalSuccess && s.message != null,
    listener: (context, s) =>
        showLifeQuestMessage(context, (s as JournalSuccess).message!),
    builder: (context, state) => switch (state) {
      JournalInitial() || JournalLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      JournalFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () =>
            context.read<JournalBloc>().add(const JournalRequested()),
      ),
      JournalSuccess(:final board) => RefreshIndicator(
        color: context.lq.deepGreen,
        onRefresh: () async {
          final bloc = context.read<JournalBloc>()
            ..add(const JournalRequested());
          await bloc.stream.firstWhere(
            (s) => s is! JournalSuccess || !s.refreshing,
          );
        },
        child: _content(context, board),
      ),
    },
  );

  Widget _content(BuildContext context, JournalBoard board) {
    final s = board.summary;
    final sources = _filters[_filter]!;
    final entries = [
      for (final e in board.entries)
        if (sources.isEmpty || sources.contains(e.source)) e,
    ];
    return LifeQuestPage(
      title: 'Diario',
      subtitle: 'La crónica de tu aventura.',
      children: [
        const LifeQuestSectionHeading('ESTA SEMANA'),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(child: _stat('XP', s.xp, s.xpPrev)),
            const SizedBox(width: 6),
            Expanded(child: _stat('Misiones', s.missions, s.missionsPrev)),
            const SizedBox(width: 6),
            Expanded(child: _stat('Mazmorras', s.cycles, s.cyclesPrev)),
            const SizedBox(width: 6),
            Expanded(
              child: LifeQuestStat(value: '${s.bestStreak}', label: 'Racha'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('BITÁCORA'),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          children: [
            for (final f in _filters.keys)
              ChoiceChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: 7),
        if (entries.isEmpty)
          const LifeQuestListRow(
            icon: Icons.auto_stories_outlined,
            title: 'Aún no hay páginas aquí',
            subtitle:
                'Cada misión, hábito y Mazmorra quedará escrita en tu Diario.',
          ),
        for (final e in entries)
          LifeQuestListRow(
            icon: e.completed
                ? Icons.check_circle_outline
                : Icons.remove_circle_outline,
            title: e.title ?? _sourceLabel(e.source),
            subtitle:
                '${_sourceLabel(e.source)} · ${LifeQuestDates.dayTime(e.occurredAt)}',
            trailing: _change(e),
          ),
      ],
    );
  }

  /// Valor de la semana con la diferencia frente a la anterior.
  static Widget _stat(String label, int value, int prev) {
    final diff = value - prev;
    return LifeQuestStat(
      value: '$value',
      label: diff == 0 ? label : '$label ${diff > 0 ? '▲' : '▼'}${diff.abs()}',
    );
  }

  static String? _change(JournalEntry e) {
    final parts = [
      if (e.xp > 0) '+${e.xp} XP',
      if (e.coins > 0) '+${e.coins} 🪙',
      if (e.hp != 0) '${e.hp > 0 ? '+' : '−'}${e.hp.abs()} vida',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String _sourceLabel(JournalSource source) => switch (source) {
    JournalSource.task => 'Misión',
    JournalSource.npc => 'Misión de NPC',
    JournalSource.project => 'Proyecto',
    JournalSource.goal => 'Meta',
    JournalSource.habit => 'Hábito',
    JournalSource.dungeon => 'Mazmorra',
    JournalSource.dailyChest => 'Cofre diario',
    JournalSource.achievement => 'Logro',
  };
}
