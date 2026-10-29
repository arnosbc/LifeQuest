import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';

/// Lo que decidió el Diagnosis Tool: guardarla, convertirla o llevarla a
/// S.M.A.R.T. con [goalTitle] como nombre de la Meta (RF-014).
class GtdOutcome {
  const GtdOutcome.shelf(ThoughtShelf this.shelf)
    : conversion = null,
      goalTitle = null;
  const GtdOutcome.convert(Conversion this.conversion)
    : shelf = null,
      goalTitle = null;
  const GtdOutcome.goal(String this.goalTitle)
    : shelf = null,
      conversion = null;

  final ThoughtShelf? shelf;
  final Conversion? conversion;
  final String? goalTitle;
}

/// Diagnosis Tool G.T.D. (CLAUDE.md §5): checklist cerrado, sin IA.
class GtdSheet extends StatefulWidget {
  const GtdSheet({super.key, required this.thought});

  final Thought thought;

  @override
  State<GtdSheet> createState() => _GtdSheetState();
}

enum _Step { actionable, steps, twoMinutes, owner, delegate, details }

class _GtdSheetState extends State<GtdSheet> {
  late final _title = TextEditingController(text: widget.thought.content);
  final _who = TextEditingController();
  _Step _step = _Step.actionable;
  ThoughtPriority _priority = ThoughtPriority.low;
  DateTime? _due;

  @override
  void dispose() {
    _title.dispose();
    _who.dispose();
    super.dispose();
  }

  void _finish(GtdOutcome outcome) => Navigator.pop(context, outcome);

  void _convert(ThoughtKind kind) {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    _finish(
      GtdOutcome.convert(
        Conversion(
          thoughtId: widget.thought.id,
          kind: kind,
          title: title,
          priority: _priority,
          dueDate: _due,
          delegatedTo: kind == ThoughtKind.delegated ? _who.text.trim() : null,
        ),
      ),
    );
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDate: _due ?? now,
    );
    if (day != null) {
      setState(() => _due = DateTime(day.year, day.month, day.day, 23, 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (question, options) = switch (_step) {
      _Step.actionable => (
        '¿Es accionable?',
        [
          ('Sí, requiere hacer algo', () => _go(_Step.steps)),
          (
            'No: guárdala en Algún día',
            () => _finish(const GtdOutcome.shelf(ThoughtShelf.someday)),
          ),
          (
            'No: es una Referencia',
            () => _finish(const GtdOutcome.shelf(ThoughtShelf.reference)),
          ),
        ],
      ),
      _Step.steps => (
        '¿Es un solo paso o varios?',
        [
          ('Un solo paso', () => _go(_Step.twoMinutes)),
          ('Varios, en semanas: Proyecto', () => _convert(ThoughtKind.project)),
          (
            'Un resultado de meses: Meta',
            () {
              final title = _title.text.trim();
              if (title.isNotEmpty) _finish(GtdOutcome.goal(title));
            },
          ),
        ],
      ),
      _Step.twoMinutes => (
        '¿Se hace en 2 minutos?',
        [
          ('Sí: la hago ya', () => _convert(ThoughtKind.done)),
          ('No, toma más', () => _go(_Step.owner)),
        ],
      ),
      _Step.owner => (
        '¿Eres la persona correcta para hacerla?',
        [
          ('Sí, me toca a mí', () => _go(_Step.details)),
          ('No, la delego', () => _go(_Step.delegate)),
        ],
      ),
      _Step.delegate => (
        '¿A quién se la delegas?',
        [('Delegar', () => _convert(ThoughtKind.delegated))],
      ),
      _Step.details => (
        '¿Tiene un momento específico?',
        [('Crear misión', () => _convert(ThoughtKind.task))],
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: context.lq.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Diagnóstico G.T.D.',
              style: TextStyle(color: context.lq.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              question,
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (_step != _Step.actionable)
              TextField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            if (_step == _Step.delegate)
              TextField(
                controller: _who,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: '¿A quién? (opcional)',
                ),
              ),
            if (_step == _Step.details || _step == _Step.delegate) ...[
              const SizedBox(height: 4),
              SegmentedButton<ThoughtPriority>(
                segments: const [
                  ButtonSegment(
                    value: ThoughtPriority.low,
                    label: Text('Baja'),
                  ),
                  ButtonSegment(
                    value: ThoughtPriority.medium,
                    label: Text('Media'),
                  ),
                  ButtonSegment(
                    value: ThoughtPriority.high,
                    label: Text('Alta'),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDue,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _due == null
                      ? 'Sin fecha: próxima acción'
                      : 'Para el ${LifeQuestDates.day(_due!)}',
                ),
              ),
              const SizedBox(height: 8),
            ],
            for (final (label, onTap) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 48,
                  child: FilledButton.tonal(
                    onPressed: onTap,
                    child: Text(label),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _go(_Step step) => setState(() => _step = step);
}
