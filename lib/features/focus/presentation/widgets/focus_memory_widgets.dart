import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/resources_sheet.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';

/// Lo que Foco deja escrito: prueba de cada paso, repaso al empezar y
/// «Dónde lo dejé» al cerrar.

/// Tras marcar un paso: «¿Qué hiciste?» con nota o foto. Opcional; no
/// bloquea nada.
class StepProofPrompt extends StatelessWidget {
  const StepProofPrompt({
    super.key,
    required this.stepTitle,
    required this.busy,
    required this.onProof,
    required this.onSkip,
  });

  final String stepTitle;
  final bool busy;
  final ValueChanged<ResourceDraft> onProof;
  final VoidCallback onSkip;

  Future<void> _note(BuildContext context) async {
    final text = await askLifeQuestText(
      context,
      title: '¿Qué hiciste?',
      label: 'Lo que lograste o dónde te trabaste',
      confirmLabel: 'Guardar',
      maxLength: 500,
    );
    if (text != null && text.trim().isNotEmpty) {
      onProof(ResourceDraft.note(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('«$stepTitle» hecho', style: QText.label(q.text)),
          const SizedBox(height: 2),
          Text(
            'Deja una prueba: te sirve para repasar y para saber que avanzas.',
            style: QText.meta(q.text2),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => _note(context),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('Nota'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
              ResourcePickButtons(
                enabled: !busy,
                picks: const [ResourcePick.camera, ResourcePick.gallery],
                onPicked: onProof,
              ),
              TextButton(
                onPressed: busy ? null : onSkip,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Al empezar: lo que el usuario dejó escrito la última vez y, con la IA,
/// preguntas para comprobar que lo recuerda.
class RecallCard extends StatefulWidget {
  const RecallCard({
    super.key,
    required this.task,
    required this.questions,
    required this.asking,
    required this.onAsk,
    required this.onDismiss,
  });

  final FocusTask task;
  final List<String>? questions;
  final bool asking;
  final VoidCallback onAsk;
  final VoidCallback onDismiss;

  @override
  State<RecallCard> createState() => _RecallCardState();
}

class _RecallCardState extends State<RecallCard> {
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final questions = widget.questions;
    // Con preguntas, las notas se esconden: primero intenta recordar.
    final notesVisible = questions == null || _showNotes;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repaso · 1 minuto', style: QText.meta(q.text2)),
          const SizedBox(height: 4),
          Text('La última vez en «${widget.task.title}»', style: QText.title3(q.text)),
          if (questions != null) ...[
            const SizedBox(height: 8),
            Text('¿Puedes responder sin mirar?', style: QText.meta(q.text2)),
            for (final question in questions)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• $question', style: QText.body(q.text)),
              ),
          ],
          if (notesVisible) ...[
            const SizedBox(height: 8),
            for (final note in widget.task.recallNotes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(note, style: QText.body(q.text2)),
              ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: [
              if (questions == null)
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: widget.asking ? null : widget.onAsk,
                  icon: const Icon(Icons.quiz_outlined, size: 20),
                  label: Text(widget.asking ? 'Pensando…' : 'Hazme preguntas'),
                )
              else if (!_showNotes)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => setState(() => _showNotes = true),
                  child: const Text('Ver mis notas'),
                ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: widget.onDismiss,
                child: const Text('Listo, a trabajar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Al cerrar: por cada tarea sin terminar, una línea «¿Dónde quedaste?»
/// que la app propone con el siguiente paso.
class ResumeNotesCard extends StatelessWidget {
  const ResumeNotesCard({
    super.key,
    required this.tasks,
    required this.saved,
    required this.onSave,
    this.distractions = 0,
  });

  final List<FocusTask> tasks;
  final Set<String> saved;
  final void Function(String taskId, String note) onSave;
  final int distractions;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final open = tasks.where((t) => !t.done).take(3).toList();
    if (open.isEmpty && distractions == 0) return const SizedBox.shrink();
    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (open.isNotEmpty) ...[
            Text('Dónde lo dejaste', style: QText.title3(q.text)),
            Text(
              'Una línea para retomar sin pensar la próxima vez.',
              style: QText.meta(q.text2),
            ),
            for (final t in open)
              _ResumeField(
                key: ValueKey(t.id),
                task: t,
                saved: saved.contains(t.id),
                onSave: (note) => onSave(t.id, note),
              ),
          ],
          if (distractions > 0) ...[
            const SizedBox(height: 8),
            Text(
              distractions == 1
                  ? '1 idea quedó en la Bandeja para decidirla después.'
                  : '$distractions ideas quedaron en la Bandeja para decidirlas después.',
              style: QText.meta(q.text2),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResumeField extends StatefulWidget {
  const _ResumeField({
    super.key,
    required this.task,
    required this.saved,
    required this.onSave,
  });

  final FocusTask task;
  final bool saved;
  final ValueChanged<String> onSave;

  @override
  State<_ResumeField> createState() => _ResumeFieldState();
}

class _ResumeFieldState extends State<_ResumeField> {
  late final _text = TextEditingController(
    text: widget.task.resumeSuggestion,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.task.title, style: QText.label(q.text)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Me quedé en… / Lo siguiente es…',
                    counterText: '',
                  ),
                  onSubmitted: widget.onSave,
                ),
              ),
              widget.saved
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Guardado', style: QText.meta(q.text2)),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => widget.onSave(_text.text),
                      child: const Text('Guardar'),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
