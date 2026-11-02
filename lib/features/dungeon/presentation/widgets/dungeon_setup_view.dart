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
    this.initialTaskId,
  });

  final DungeonBoard board;
  final bool busy;
  final void Function(int totalMinutes, int cycleMinutes, List<String> taskIds)
  onStart;

  /// Llega marcada desde «Empezar en Foco».
  final String? initialTaskId;

  @override
  State<DungeonSetupView> createState() => _DungeonSetupViewState();
}

class _DungeonSetupViewState extends State<DungeonSetupView> {
  int _cycle = 25;
  int _total = 60;
  final List<String> _picked = [];

  @override
  void initState() {
    super.initState();
    _pickInitial();
  }

  @override
  void didUpdateWidget(DungeonSetupView old) {
    super.didUpdateWidget(old);
    if (old.initialTaskId != widget.initialTaskId) _pickInitial();
  }

  void _pickInitial() {
    final id = widget.initialTaskId;
    if (id == null || _picked.contains(id)) return;
    if (_picked.length >= widget.board.maxTasks) return;
    if (widget.board.candidates.any((t) => t.id == id)) _picked.add(id);
  }

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
          'TAREAS DE LA SESIÓN',
          action: '${_picked.length} / ${widget.board.maxTasks}',
        ),
        const SizedBox(height: 6),
        if (candidates.isEmpty)
          LifeQuestSurface(
            child: Text(
              'No tienes tareas abiertas. Crea una en el Planificador y vuelve al Modo Foco.',
              style: TextStyle(color: context.lq.muted, fontSize: 11),
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
              style: TextStyle(color: context.lq.ink, fontSize: 12),
            ),
          ),
        const SizedBox(height: 9),
        Text(
          'XP estimada: ${cycles * widget.board.cycleXp} por $cycles bloques',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.lq.muted, fontSize: 11),
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
            label: const Text('Empezar Modo Foco'),
            style: FilledButton.styleFrom(
              backgroundColor: context.lq.deepGreen,
            ),
          ),
        ),
      ],
    );
  }
}
