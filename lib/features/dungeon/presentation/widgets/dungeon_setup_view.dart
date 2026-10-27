import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/cycle_duration_card.dart';

/// Antes de entrar: duración, ciclo y mochila (hasta [DungeonBoard.maxTasks]).
class DungeonSetupView extends StatefulWidget {
  const DungeonSetupView({
    super.key,
    required this.board,
    required this.busy,
    required this.onStart,
  });

  final DungeonBoard board;
  final bool busy;
  final void Function(int totalMinutes, int cycleMinutes, List<String> taskIds)
  onStart;

  @override
  State<DungeonSetupView> createState() => _DungeonSetupViewState();
}

class _DungeonSetupViewState extends State<DungeonSetupView> {
  int _cycle = 25;
  int _total = 60;
  final List<String> _picked = [];

  @override
  Widget build(BuildContext context) {
    final candidates = widget.board.candidates;
    final full = _picked.length >= widget.board.maxTasks;
    final cycles = _total ~/ _cycle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CycleDurationCard(
          breaksNote:
              'Descansos: ${widget.board.shortBreakMinutes} min, y '
              '${widget.board.longBreakMinutes} min cada '
              '${widget.board.longBreakEveryNCycles} ciclos.',
          cycleMinutes: _cycle,
          totalMinutes: _total,
          onCycleChanged: (v) => setState(() {
            _cycle = v;
            // La sesión debe dar al menos un ciclo.
            while (_total < _cycle) {
              _total += 30;
            }
          }),
          onTotalChanged: (v) => setState(() => _total = v),
        ),
        const SizedBox(height: 9),
        LifeQuestSectionHeading(
          'MOCHILA DE MISIONES',
          action: '${_picked.length} / ${widget.board.maxTasks}',
        ),
        const SizedBox(height: 6),
        if (candidates.isEmpty)
          const LifeQuestSurface(
            child: Text(
              'No tienes misiones abiertas. Crea una en Misiones y vuelve a entrar.',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 11),
            ),
          ),
        for (final task in candidates)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _picked.contains(task.id),
            onChanged: !_picked.contains(task.id) && full
                ? null
                : (on) => setState(
                    () => on! ? _picked.add(task.id) : _picked.remove(task.id),
                  ),
            title: Text(
              task.title,
              style: const TextStyle(color: LifeQuestColors.ink, fontSize: 12),
            ),
          ),
        const SizedBox(height: 9),
        Text(
          'Recompensa estimada: ${cycles * widget.board.cycleXp} XP por $cycles ciclos',
          textAlign: TextAlign.center,
          style: const TextStyle(color: LifeQuestColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _picked.isEmpty || widget.busy
                ? null
                : () => widget.onStart(_total, _cycle, List.of(_picked)),
            icon: widget.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: const Text('Entrar a la Mazmorra'),
            style: FilledButton.styleFrom(
              backgroundColor: LifeQuestColors.deepGreen,
            ),
          ),
        ),
      ],
    );
  }
}
