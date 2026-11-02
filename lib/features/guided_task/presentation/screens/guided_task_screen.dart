import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_evidence.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_review.dart';
import 'package:proyecto_movil/features/guided_task/presentation/blocs/guided_task_bloc.dart';

/// Tarea guiada (plan B1, B2 y B6): objetivo, el paso que toca ahora con sus
/// pistas a pedido, todos los pasos marcables y cómo avanzó la tarea.
/// Necesita un [GuidedTaskBloc] por encima (lo provee el router).
class GuidedTaskScreen extends StatefulWidget {
  const GuidedTaskScreen({
    super.key,
    required this.onStartFocus,
    this.onOpenDocument,
  });

  /// Abre el Modo Foco con esta tarea elegida.
  final ValueChanged<String> onStartFocus;

  /// Abre (o crea) el documento de la tarea: (id, título).
  final void Function(String taskId, String title)? onOpenDocument;

  @override
  State<GuidedTaskScreen> createState() => _GuidedTaskScreenState();
}

class _GuidedTaskScreenState extends State<GuidedTaskScreen> {
  /// Pistas mostradas: se revelan de a una para pensar antes (B2).
  int _hints = 0;
  bool _pickingEvidence = false;

  void _split(BuildContext context) =>
      _askSteps(context, context.read<GuidedTaskBloc>());

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<GuidedTaskBloc, GuidedTaskState>(
        listenWhen: (_, s) => s is GuidedTaskSuccess && s.message != null,
        listener: (context, s) =>
            showLifeQuestMessage(context, (s as GuidedTaskSuccess).message!),
        builder: (context, state) => switch (state) {
          GuidedTaskLoading() => Center(
            child: CircularProgressIndicator(color: context.q.ink),
          ),
          GuidedTaskFailure(:final message) => LifeQuestErrorView(
            message: message,
            onRetry: () => Navigator.of(context).maybePop(),
          ),
          GuidedTaskSuccess() => _content(context, state),
        },
      );

  Widget _content(BuildContext context, GuidedTaskSuccess state) {
    final task = state.task;
    final bloc = context.read<GuidedTaskBloc>();
    final hints = task.guide?.hints ?? const <String>[];
    final search = task.guide?.search ?? const <String>[];
    final current = task.completed ? null : task.current;
    void focus() => widget.onStartFocus(task.id);
    return LifeQuestPage(
      title: task.title,
      kicker: task.steps.isEmpty ? 'Tarea' : 'Tarea guiada',
      icon: QIcons.focus,
      subtitle:
          task.guide?.objective ??
          (task.steps.isEmpty
              ? (task.description ?? 'Complétala cuando esté lista.')
              : 'Avanza paso a paso, a tu ritmo.'),
      children: [
        _ProgressCard(task: task),
        const SizedBox(height: QSpace.l),
        if (widget.onOpenDocument case final open?) ...[
          QuestlyButton(
            label: 'Documento de la tarea',
            icon: QIcons.book,
            variant: QuestlyButtonVariant.secondary,
            onPressed: () => open(task.id, task.title),
          ),
          const SizedBox(height: QSpace.m),
        ],
        if (task.completed)
          _Banner(
            text: '¡Tarea completada! Ganaste ${task.xpReward} XP en total.',
          )
        else if (!task.inFocus) ...[
          // 040: los pasos se marcan y la tarea se completa dentro del Foco.
          QuestlyButton(
            label: task.steps.isEmpty
                ? 'Empezar en Foco'
                : 'Empezar en Foco para avanzar',
            icon: QIcons.focus,
            onPressed: focus,
          ),
          if (task.steps.isEmpty) ...[
            const SizedBox(height: QSpace.s),
            QuestlyButton(
              label: 'Dividir en pasos',
              icon: QIcons.plus,
              variant: QuestlyButtonVariant.tonal,
              onPressed: state.busy ? null : () => _split(context),
              disabledReason: 'Guardando…',
            ),
          ],
        ] else if (current != null) ...[
          _NowCard(
            step: current,
            total: task.steps.length,
            busy: state.busy || _pickingEvidence,
            reviewing: state.reviewingStepId == current.id || _pickingEvidence,
            onDone: () => bloc.add(GuidedStepToggled(current.id)),
            onReview: () => _reviewEvidence(current, bloc),
          ),
          if (state.review != null) ...[
            const SizedBox(height: QSpace.m),
            _ReviewCard(review: state.review!),
          ],
          if (hints.isNotEmpty) ...[
            const SizedBox(height: QSpace.m),
            for (final hint in hints.take(_hints)) _HintCard(text: hint),
            if (_hints < hints.length)
              QuestlyButton(
                label: _hints == 0
                    ? 'Necesito una pista'
                    : 'Otra pista (${_hints + 1} de ${hints.length})',
                icon: QIcons.spark,
                variant: QuestlyButtonVariant.tonal,
                onPressed: () => setState(() => _hints++),
              ),
          ],
        ] else ...[
          // Sin pasos y en Foco: se completa de una vez o se divide.
          QuestlyButton(
            label: 'Completar tarea',
            onPressed: state.busy
                ? null
                : () => bloc.add(const GuidedTaskCompleted()),
            disabledReason: 'Completando…',
          ),
          const SizedBox(height: QSpace.s),
          QuestlyButton(
            label: 'Dividir en pasos',
            icon: QIcons.plus,
            variant: QuestlyButtonVariant.tonal,
            onPressed: state.busy ? null : () => _split(context),
            disabledReason: 'Guardando…',
          ),
        ],
        if (task.steps.isNotEmpty) ...[
          const SizedBox(height: QSpace.xl),
          _Title('Todos los pasos'),
          Padding(
            padding: const EdgeInsets.only(bottom: QSpace.s),
            child: Text(
              'Completa el paso actual para habilitar el siguiente.',
              style: QText.body(context.q.text2),
            ),
          ),
          QuestlyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, step) in task.steps.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.q.line),
                  _StepRow(
                    step: step,
                    busy: state.busyStepId == step.id,
                    enabled:
                        !state.busy &&
                        !task.completed &&
                        task.inFocus &&
                        current?.id == step.id,
                    onTap: () => bloc.add(GuidedStepToggled(step.id)),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (search.isNotEmpty) ...[
          const SizedBox(height: QSpace.xl),
          _Title('Para aprender más, busca'),
          Wrap(
            spacing: QSpace.s,
            runSpacing: QSpace.s,
            children: [
              for (final term in search)
                Chip(
                  label: Text(term, style: QText.label(context.q.riverInk)),
                  backgroundColor: context.q.riverTint,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        const SizedBox(height: QSpace.xl),
        _Title('Cómo avanzó'),
        _Timeline(task: task),
      ],
    );
  }

  Future<void> _reviewEvidence(GuidedStep step, GuidedTaskBloc bloc) async {
    setState(() => _pickingEvidence = true);
    try {
      final files = await _pickEvidence();
      if (!mounted || files == null || files.isEmpty) return;
      if (files.length > GuidedStepEvidence.maxFiles) {
        _showMessage('Selecciona hasta 5 archivos por revisión.');
        return;
      }

      var totalBytes = 0;
      final evidence = <GuidedStepEvidence>[];
      for (final file in files) {
        final size = await file.length();
        if (!mounted) return;
        if (size > GuidedStepEvidence.maxBytes) {
          _showMessage('${file.name} supera el límite de 10 MB.');
          return;
        }
        totalBytes += size;
        if (totalBytes > GuidedStepEvidence.maxTotalBytes) {
          _showMessage('El total de archivos no puede superar 10 MB.');
          return;
        }
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        if (bytes.length != size ||
            bytes.length > GuidedStepEvidence.maxBytes) {
          _showMessage('No pudimos leer ${file.name} completo.');
          return;
        }
        evidence.add(
          GuidedStepEvidence(
            name: file.name,
            mimeType: _mimeType(_extension(file.name)),
            bytes: bytes,
          ),
        );
      }
      if (!mounted) return;

      final consent = await showQuestlyDialog<bool>(
        context,
        title: 'Enviar evidencia para revisión',
        message:
            'Los archivos se enviarán a Gemini para analizar este paso y no se '
            'guardarán en LifeQuest. Gemini puede procesar el contenido según '
            'sus propias condiciones; evita incluir datos personales o sensibles. '
            'La revisión puede equivocarse y no decide si puedes avanzar.',
        actions: [
          QuestlyButton(
            label: 'Enviar a revisión',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          QuestlyButton(
            label: 'Cancelar',
            variant: QuestlyButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
      if (!mounted || consent != true) return;
      bloc.add(GuidedStepReviewRequested(stepId: step.id, evidence: evidence));
    } on Exception {
      _showMessage('No pudimos leer esos archivos. Prueba con otros.');
    } finally {
      if (mounted) setState(() => _pickingEvidence = false);
    }
  }

  /// Pregunta si la evidencia es una foto nueva o archivos del teléfono;
  /// null si cierra la hoja.
  Future<List<XFile>?> _pickEvidence() async {
    final camera = await showQuestlySheet<bool>(
      context,
      title: 'Agregar evidencia',
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Buscar en archivos'),
              subtitle: const Text('Imágenes, PDF, Word o texto. Hasta 5.'),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    if (camera == null) return null;
    if (camera) {
      // Reducida y en JPEG: cabe holgada en el límite de 10 MB.
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      return photo == null ? const [] : [photo];
    }
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Evidencia del paso',
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'heic',
        'heif',
        'pdf',
        'docx',
        'txt',
        'md',
        'markdown',
      ],
    );
    return [for (final file in files) file.xFile];
  }

  static String? _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? null : name.substring(dot + 1);
  }

  void _showMessage(String message) {
    if (mounted) showLifeQuestMessage(context, message);
  }

  static String _mimeType(String? extension) => switch (extension
      ?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'pdf' => 'application/pdf',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt' || 'md' || 'markdown' => 'text/plain',
    _ => 'application/octet-stream',
  };
}

/// Pide los pasos, uno por línea (máx. 8), y los guarda.
Future<void> _askSteps(BuildContext context, GuidedTaskBloc bloc) async {
  final controller = TextEditingController();
  final steps = await showQuestlyDialog<List<String>>(
    context,
    title: 'Dividir en pasos',
    message: 'Escribe un paso por línea, empezando por uno pequeño. Máx. 8.',
    content: TextField(
      controller: controller,
      autofocus: true,
      minLines: 4,
      maxLines: 8,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: 'Abrir el documento\nEscribir el título\n…',
        border: OutlineInputBorder(),
      ),
    ),
    actions: [
      Builder(
        builder: (context) => QuestlyButton(
          label: 'Guardar pasos',
          onPressed: () => Navigator.of(context).pop(
            [
              for (final line in controller.text.split('\n'))
                if (line.trim().isNotEmpty) line.trim(),
            ].take(8).toList(),
          ),
        ),
      ),
    ],
  );
  controller.dispose();
  if (steps != null && steps.isNotEmpty) bloc.add(GuidedStepsSet(steps));
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.task});

  final GuidedTask task;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final total = task.steps.length;
    final done = task.completed ? total : task.doneCount;
    final value = total == 0 ? (task.completed ? 1.0 : 0.0) : done / total;
    final earned = task.completed ? task.xpReward : task.paidXp;
    return QuestlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? (task.completed ? 'Completada' : 'Sin pasos')
                      : task.completed
                      ? 'Los $total pasos, hechos'
                      : 'Paso ${done + 1 > total ? total : done + 1} de $total',
                  style: QText.title3(q.text),
                ),
              ),
              Text(
                '$earned / ${task.xpReward} XP',
                style: QText.number(q.ink, size: 14),
              ),
            ],
          ),
          const SizedBox(height: QSpace.m),
          Semantics(
            label: '$done de $total pasos hechos',
            excludeSemantics: true,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: context.motion(const Duration(milliseconds: 600)),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(QRadius.pill),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  color: q.accent,
                  backgroundColor: q.track,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El paso que toca ahora, grande y con su acción principal (B2).
class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.step,
    required this.total,
    required this.busy,
    required this.reviewing,
    required this.onDone,
    required this.onReview,
  });

  final GuidedStep step;
  final int total;
  final bool busy;
  final bool reviewing;
  final VoidCallback onDone;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final last = step.position == total;
    return QuestlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('AHORA', style: QText.meta(q.ink)),
          const SizedBox(height: QSpace.s),
          Semantics(
            header: true,
            child: Text(
              step.title,
              style: QText.title3(q.text).copyWith(fontSize: 19, height: 1.3),
            ),
          ),
          const SizedBox(height: QSpace.l),
          QuestlyButton(
            label: last ? 'Listo, terminar la tarea' : 'Listo, siguiente paso',
            onPressed: busy ? null : onDone,
            disabledReason: 'Guardando…',
          ),
          const SizedBox(height: QSpace.s),
          QuestlyButton(
            label: reviewing
                ? 'Preparando revisión…'
                : 'Revisar evidencia con IA',
            icon: QIcons.spark,
            variant: QuestlyButtonVariant.secondary,
            onPressed: busy ? null : onReview,
            disabledReason: 'Analizando…',
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final GuidedStepReview review;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final (label, icon) = switch (review.assessment) {
      GuidedStepAssessment.supports => (
        'La evidencia coincide',
        Icons.check_circle_outline,
      ),
      GuidedStepAssessment.partial => (
        'Hay avance parcial',
        Icons.info_outline,
      ),
      GuidedStepAssessment.insufficient => (
        'No se pudo confirmar con estos archivos',
        Icons.help_outline,
      ),
    };
    return QuestlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: q.ink),
              const SizedBox(width: QSpace.s),
              Expanded(child: Text(label, style: QText.title3(q.text))),
            ],
          ),
          const SizedBox(height: QSpace.s),
          Text(review.feedback, style: QText.body(q.text)),
          if (review.nextAction.isNotEmpty) ...[
            const SizedBox(height: QSpace.s),
            Text(review.nextAction, style: QText.body(q.text2)),
          ],
          const SizedBox(height: QSpace.m),
          Text(
            'Revisión orientativa: tú decides cuándo el paso está listo.',
            style: QText.body(q.text2).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      margin: const EdgeInsets.only(bottom: QSpace.s),
      padding: const EdgeInsets.all(QSpace.m),
      decoration: BoxDecoration(
        color: q.tint,
        borderRadius: BorderRadius.circular(QRadius.block),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QIcon(QIcons.spark, color: q.ink, size: 20),
          const SizedBox(width: QSpace.s),
          Expanded(
            child: Text(
              text,
              style: QText.body(q.text3).copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final GuidedStep step;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return MergeSemantics(
      child: Semantics(
        checked: step.done,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 26,
                    child: busy
                        ? CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: q.ink,
                          )
                        : Icon(
                            step.done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: step.done ? q.accent : q.text2,
                          ),
                  ),
                  const SizedBox(width: QSpace.m),
                  Expanded(
                    child: Text(
                      '${step.position}. ${step.title}',
                      style: QText.body(step.done ? q.text2 : q.text).copyWith(
                        fontSize: 15,
                        decoration: step.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                  if (step.paidXp > 0) ...[
                    const SizedBox(width: QSpace.s),
                    Text(
                      '+${step.paidXp} XP',
                      style: QText.number(q.ink, size: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cómo avanzó la tarea (B6): se deriva de las fechas, sin datos extra.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.task});

  final GuidedTask task;

  static String _when(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.day}/${d.month} · ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final events = <(DateTime, String)>[
      (task.createdAt, 'Creada'),
      for (final s in task.steps)
        if (s.doneAt != null) (s.doneAt!, 'Paso ${s.position} hecho'),
      if (task.completedAt != null) (task.completedAt!, 'Completada'),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return QuestlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (at, what) in events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: q.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: QSpace.m),
                  Expanded(child: Text(what, style: QText.body(q.text))),
                  Text(_when(at), style: QText.number(q.text2, size: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      padding: const EdgeInsets.all(QSpace.l),
      decoration: BoxDecoration(
        color: q.tint,
        borderRadius: BorderRadius.circular(QRadius.card),
      ),
      child: Text(text, style: QText.title3(q.ink)),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: QSpace.s),
    child: Semantics(
      header: true,
      child: Text(text, style: QText.title3(context.q.text)),
    ),
  );
}
