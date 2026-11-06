import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_theme.dart';
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
    this.preselected,
  });

  final DungeonBoard board;

  /// Tarea que llega desde «Empezar foco»: entra ya en la mochila.
  final String? preselected;
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
  void initState() {
    super.initState();
    _pick(widget.preselected);
  }

  @override
  void didUpdateWidget(DungeonSetupView old) {
    super.didUpdateWidget(old);
    if (widget.preselected != old.preselected) _pick(widget.preselected);
  }

  void _pick(String? id) {
    if (id == null ||
        _picked.contains(id) ||
        _picked.length >= widget.board.maxTasks ||
        !widget.board.candidates.any((t) => t.id == id)) {
      return;
    }
    _picked.add(id);
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
        const SizedBox(height: 16),
        SessionRoute(
          board: widget.board,
          cycles: cycles,
          cycleMinutes: _cycle,
          now: DateTime.now(),
        ),
        const SizedBox(height: 20),
        LifeQuestSectionHeading(
          'TAREAS PARA ESTA SESIÓN',
          action: '${_picked.length} / ${widget.board.maxTasks}',
        ),
        const SizedBox(height: 6),
        if (candidates.isEmpty)
          const LifeQuestEmptyState(
            compact: true,
            illustration: LifeQuestIllustration.blank,
            title: 'No tienes tareas abiertas',
            message: 'Crea una en Tareas y vuelve para concentrarte en ella.',
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
            title: Text(task.title, style: QText.body(context.q.text)),
          ),
        const SizedBox(height: 9),
        Text(
          'Recompensa estimada: ${cycles * widget.board.cycleXp} XP por $cycles ciclos',
          textAlign: TextAlign.center,
          style: QText.meta(context.q.text2),
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
            label: const Text('Empezar foco'),
          ),
        ),
      ],
    );
  }
}

/// Ruta de la sesión: bloques de foco y descansos a escala, y a qué hora
/// terminarías si empiezas ahora.
class SessionRoute extends StatelessWidget {
  const SessionRoute({
    super.key,
    required this.board,
    required this.cycles,
    required this.cycleMinutes,
    required this.now,
  });

  final DungeonBoard board;
  final int cycles;
  final int cycleMinutes;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    // Descanso tras cada ciclo salvo el último.
    final breaks = [
      for (var i = 1; i < cycles; i++) board.breakAfter(i).inMinutes,
    ];
    final minutes =
        cycles * cycleMinutes + breaks.fold<int>(0, (a, b) => a + b);
    final end = now.add(Duration(minutes: minutes));
    final hhmm =
        '${end.hour.toString().padLeft(2, '0')}:'
        '${end.minute.toString().padLeft(2, '0')}';
    return LifeQuestSurface(
      color: q.tint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('Tu ruta', style: QText.title3(q.text))),
              Text('Terminas a las $hhmm', style: QText.meta(q.text2)),
            ],
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  for (var i = 0; i < cycles; i++) ...[
                    Expanded(
                      flex: cycleMinutes,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: q.mark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('${i + 1}', style: QText.meta(q.card)),
                          ),
                        ),
                      ),
                    ),
                    if (i < breaks.length)
                      Expanded(
                        flex: breaks[i],
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 6,
                          decoration: BoxDecoration(
                            color: q.text2,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$cycles ${cycles == 1 ? 'ciclo' : 'ciclos'} de $cycleMinutes min'
            '${breaks.isEmpty ? '' : ' · ${breaks.length} '
                      '${breaks.length == 1 ? 'descanso' : 'descansos'}'}'
            ' · ${CycleDurationCard.hours(minutes)} en total',
            style: QText.meta(q.text2),
          ),
        ],
      ),
    );
  }
}
