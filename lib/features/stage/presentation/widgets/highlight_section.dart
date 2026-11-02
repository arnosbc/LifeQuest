import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

enum _Range { all, today, tomorrow, week }

/// Prioridades del Planificador (RF-089) con los filtros de Stage.dc.html:
/// Todas · Hoy · Mañana · 7 días, según la fecha límite de cada tarea. El
/// orden urgent → high → medium → low → pending lo trae el servidor.
class HighlightSection extends StatefulWidget {
  const HighlightSection({
    super.key,
    required this.items,
    required this.total,
    required this.onOpenAll,
    required this.labelFor,
  });

  final List<HighlightItem> items;
  final int total;
  final VoidCallback onOpenAll;
  final String Function(StageBucket bucket) labelFor;

  @override
  State<HighlightSection> createState() => _HighlightSectionState();
}

class _HighlightSectionState extends State<HighlightSection> {
  _Range _range = _Range.all;

  bool _matches(HighlightItem item, DateTime now) {
    if (_range == _Range.all) return true;
    final due = item.dueDate;
    if (due == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final diff = day.difference(today).inDays;
    return switch (_range) {
      // Lo vencido también es para hoy.
      _Range.today => diff <= 0,
      _Range.tomorrow => diff == 1,
      _Range.week => diff <= 6,
      _Range.all => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final now = DateTime.now();
    final shown = [
      for (final i in widget.items)
        if (_matches(i, now)) i,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LifeQuestSectionHeading(
          'PRIORIDADES',
          action: 'Ver tareas (${widget.total})',
          onTap: widget.onOpenAll,
        ),
        const SizedBox(height: QSpace.s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (range, label) in const [
                (_Range.all, 'Todas'),
                (_Range.today, 'Hoy'),
                (_Range.tomorrow, 'Mañana'),
                (_Range.week, '7 días'),
              ]) ...[
                QuestlyFilterChip(
                  label: label,
                  selected: _range == range,
                  onTap: () => setState(() => _range = range),
                ),
                const SizedBox(width: QSpace.s),
              ],
            ],
          ),
        ),
        const SizedBox(height: QSpace.s),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: QSpace.s),
            child: Text(
              widget.items.isEmpty
                  ? 'Sin tareas abiertas. Añade una para empezar el día.'
                  : 'Nada con fecha en este rango. ¡Buen momento para adelantar algo!',
              style: QText.body(q.text2).copyWith(fontSize: 13),
            ),
          ),
        for (final item in shown)
          LifeQuestListRow(
            icon: switch (item.bucket) {
              StageBucket.urgent => Icons.bolt,
              StageBucket.pending => Icons.hourglass_empty_rounded,
              _ => Icons.flag_outlined,
            },
            title: item.title,
            subtitle: widget.labelFor(item.bucket),
          ),
      ],
    );
  }
}
