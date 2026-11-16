import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/cycle_duration_card.dart';

/// Antes de entrar: qué hacer (tareas y hábitos de hoy, hasta
/// [DungeonBoard.maxTasks]) y cuánto tiempo, que se propone solo según lo
/// elegido (068) hasta que la persona lo cambie.
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
  final void Function(
    int totalMinutes,
    int cycleMinutes,
    List<String> taskIds,
    List<String> habitIds,
  )
  onStart;

  /// Llega marcada desde «Empezar en Foco».
  final String? initialTaskId;

  /// Tiempo sugerido: lo estimado de cada cosa (o un bloque si no hay
  /// estimación), redondeado a 30 min y dentro de lo que admite el servidor.
  static int suggestedMinutes(Iterable<DungeonTask> picked, int cycle) {
    final sum = picked.fold<int>(0, (total, t) => total + t.minutesOr(cycle));
    final rounded = ((sum + 29) ~/ 30) * 30;
    final min = ((cycle + 29) ~/ 30) * 30;
    return rounded.clamp(min, 480);
  }

  @override
  State<DungeonSetupView> createState() => _DungeonSetupViewState();
}

class _DungeonSetupViewState extends State<DungeonSetupView> {
  int _cycle = 25;
  int _total = 60;

  /// Si la persona movió el tiempo, ya no se recalcula solo.
  bool _totalTouched = false;
  final List<String> _picked = [];

  @override
  void initState() {
    super.initState();
    _pickInitial();
  }

  @override
  void didUpdateWidget(DungeonSetupView old) {
    super.didUpdateWidget(old);
    // También con cada tablero nuevo: una tarea recién creada llega a las
    // candidatas después de abrir Foco con `?task=`.
    _pickInitial();
  }

  /// La tarea de `?task=` ya se marcó (o se intentó con espacio): no se
  /// vuelve a marcar si el usuario la quita.
  String? _pickedInitial;

  void _pickInitial() {
    final id = widget.initialTaskId;
    if (id == null || id == _pickedInitial) return;
    if (!widget.board.candidates.any((t) => t.id == id)) return;
    _pickedInitial = id;
    if (!_picked.contains(id) && _picked.length < widget.board.maxTasks) {
      _picked.add(id);
    }
  }

  List<DungeonTask> get _all => [
    ...widget.board.candidates,
    ...widget.board.habitCandidates,
  ];

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final full = _picked.length >= board.maxTasks;
    final picked = _all.where((t) => _picked.contains(t.id));
    if (!_totalTouched) {
      _total = DungeonSetupView.suggestedMinutes(picked, _cycle);
    }
    final cycles = _total ~/ _cycle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: MascotPose(pose: 'foco', size: 110)),
        LifeQuestSectionHeading(
          '¿EN QUÉ TE VAS A ENFOCAR?',
          action: '${_picked.length} / ${board.maxTasks}',
        ),
        const SizedBox(height: 4),
        // Marcar aquí solo elige; se confundía con completar (prueba 2026-11-14).
        Text(
          'Márcalas para llevarlas a la sesión. Los pasos y los hábitos los '
          'cumples dentro de Foco.',
          style: TextStyle(color: context.lq.muted, fontSize: 11),
        ),
        if (board.candidates.isEmpty && board.habitCandidates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LifeQuestSurface(
              child: Text(
                'No tienes tareas abiertas ni hábitos pendientes hoy. Crea una '
                'tarea en el Planificador y vuelve al Modo Foco.',
                style: TextStyle(color: context.lq.muted, fontSize: 11),
              ),
            ),
          ),
        if (board.candidates.isNotEmpty) _group(context, 'TAREAS'),
        for (final task in board.candidates) _option(context, task, full),
        if (board.habitCandidates.isNotEmpty) _group(context, 'HÁBITOS DE HOY'),
        for (final habit in board.habitCandidates) _option(context, habit, full),
        const SizedBox(height: 9),
        CycleDurationCard(
          breaksNote:
              '${_totalTouched ? 'Tiempo elegido por ti' : 'Tiempo sugerido según lo que elegiste'}'
              '. Descansos: ${board.shortBreakMinutes} min, y '
              '${board.longBreakMinutes} min cada '
              '${board.longBreakEveryNCycles} ciclos.',
          cycleMinutes: _cycle,
          totalMinutes: _total,
          onCycleChanged: (v) => setState(() {
            _cycle = v;
            // La sesión debe dar al menos un ciclo.
            while (_total < _cycle) {
              _total += 30;
            }
          }),
          onTotalChanged: (v) => setState(() {
            _totalTouched = true;
            _total = v;
          }),
        ),
        const SizedBox(height: 9),
        Text(
          'XP estimada: ${cycles * board.cycleXp} por $cycles bloques',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.lq.muted, fontSize: 11),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _picked.isEmpty || widget.busy
                ? null
                : () => widget.onStart(
                    _total,
                    _cycle,
                    [
                      for (final t in board.candidates)
                        if (_picked.contains(t.id)) t.id,
                    ],
                    [
                      for (final h in board.habitCandidates)
                        if (_picked.contains(h.id)) h.id,
                    ],
                  ),
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

  Widget _group(BuildContext context, String label) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Text(
      label,
      style: TextStyle(
        color: context.lq.muted,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _option(BuildContext context, DungeonTask item, bool full) {
    final on = _picked.contains(item.id);
    final detail = [
      if (item.stepCount > 0)
        '${item.stepCount} ${item.stepCount == 1 ? 'paso' : 'pasos'}',
      if (item.minutes != null)
        '~${CycleDurationCard.hours(item.minutes!)}'
      else
        '1 bloque',
    ].join(' · ');
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: on,
      onChanged: !on && full
          ? null
          : (value) => setState(
              () => value! ? _picked.add(item.id) : _picked.remove(item.id),
            ),
      title: Text(
        item.title,
        style: TextStyle(color: context.lq.ink, fontSize: 12),
      ),
      subtitle: Text(
        detail,
        style: TextStyle(color: context.lq.muted, fontSize: 10),
      ),
    );
  }
}
