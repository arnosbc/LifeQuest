import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';
import 'package:proyecto_movil/features/journal/presentation/blocs/journal_bloc.dart';

/// «Lo que hiciste» desde [since]: la Bitácora plegada dentro del cierre del
/// día (reemplaza la pantalla Historial). Necesita un [JournalBloc] encima.
class JournalLog extends StatefulWidget {
  const JournalLog({super.key, required this.since});

  final DateTime since;

  @override
  State<JournalLog> createState() => _JournalLogState();
}

class _JournalLogState extends State<JournalLog> {
  bool _open = false;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<JournalBloc, JournalState>(
        builder: (context, state) {
          // Sin datos (cargando o error) no se muestra: es un extra del cierre.
          if (state is! JournalSuccess) return const SizedBox.shrink();
          final entries = [
            for (final e in state.board.entries)
              if (e.completed && !e.occurredAt.isBefore(widget.since)) e,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LifeQuestSectionHeading(
                'LO QUE HICISTE · ${entries.length}',
                action: entries.isEmpty ? null : (_open ? 'Ocultar' : 'Ver'),
                onTap: entries.isEmpty
                    ? null
                    : () => setState(() => _open = !_open),
              ),
              if (entries.isEmpty)
                const LifeQuestListRow(
                  title: 'Aún nada esta semana',
                  subtitle: 'Cada tarea, hábito y foco quedará aquí.',
                ),
              if (_open)
                for (final e in entries)
                  LifeQuestListRow(
                    title: e.title ?? _label(e.source),
                    subtitle:
                        '${_label(e.source)} · ${LifeQuestDates.dayTime(e.occurredAt)}',
                    trailing: e.xp > 0 ? '+${e.xp} XP' : null,
                  ),
            ],
          );
        },
      );

  static String _label(JournalSource source) => switch (source) {
    JournalSource.task || JournalSource.npc => 'Tarea',
    JournalSource.project => 'Proyecto',
    JournalSource.goal => 'Meta',
    JournalSource.habit => 'Hábito',
    JournalSource.focus => 'Foco',
    JournalSource.dailyChest => 'Recompensa diaria',
    JournalSource.achievement => 'Logro',
  };
}
