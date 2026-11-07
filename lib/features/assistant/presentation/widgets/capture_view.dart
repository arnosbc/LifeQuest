import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';

/// Contenido de la hoja «Anotar»: escribir, revisar los chips y confirmar.
/// Al guardar cierra la hoja con `true`.
class CaptureView extends StatefulWidget {
  const CaptureView({
    super.key,
    this.initialText,
    this.startListening = false,
    this.preferInbox = false,
    this.onOpenForm,
  });

  /// «Usar el formulario» del tipo elegido; lo compone app/.
  final ValueChanged<CaptureKind>? onOpenForm;

  /// Texto compartido desde otra app: se interpreta al abrir.
  final String? initialText;

  /// Abrir dictando (micrófono de la barra de Hoy).
  final bool startListening;

  /// Lo compartido va por defecto a la Bandeja.
  final bool preferInbox;

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  late final _text = TextEditingController(text: widget.initialText);
  CaptureKind _kind = CaptureKind.task;

  static const _labels = {
    CaptureKind.task: 'Tarea',
    CaptureKind.project: 'Proyecto',
    CaptureKind.goal: 'Meta',
  };

  static const _hints = {
    CaptureKind.task: 'gym mañana 6pm cada lunes',
    CaptureKind.project: 'Mudanza de apartamento para el 30 de diciembre',
    CaptureKind.goal: 'Correr 10 km en marzo',
  };

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CaptureBloc>();
    if (widget.initialText case final text? when text.trim().isNotEmpty) {
      bloc.add(CaptureSubmitted(text));
    } else if (widget.startListening) {
      bloc.add(const CaptureListenRequested());
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<CaptureBloc>().add(CaptureSubmitted(_text.text));

  @override
  Widget build(BuildContext context) => BlocConsumer<CaptureBloc, CaptureState>(
    listenWhen: (_, s) =>
        s is CaptureSaved ||
        (s is CaptureWriting && s.heard != null) ||
        (s is CapturePreview && s.message != null) ||
        (s is CaptureWriting && s.message != null),
    listener: (context, state) {
      if (state case CaptureWriting(:final heard?)) {
        _text.text = heard;
        if (state.message == null) return;
      }
      _notify(context, state);
    },
    builder: (context, state) => switch (state) {
      CaptureWriting(:final busy, :final listening) => _writing(
        busy,
        listening,
      ),
      CapturePreview() => _preview(context, state),
      CaptureSaved() => const SizedBox(height: 120),
    },
  );

  void _notify(BuildContext context, CaptureState state) => switch (state) {
    CaptureSaved() => Navigator.pop(context, true),
    CapturePreview(:final message?) ||
    CaptureWriting(:final message?) => showLifeQuestMessage(context, message),
    _ => null,
  };

  Widget _writing(bool busy, bool listening) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!widget.preferInbox) ...[
        QuestlySegmented<CaptureKind>(
          segments: [for (final k in CaptureKind.values) (k, _labels[k]!)],
          selected: _kind,
          onChanged: busy || listening
              ? (_) {}
              : (kind) {
                  setState(() => _kind = kind);
                  context.read<CaptureBloc>().add(CaptureKindChanged(kind));
                },
        ),
        const SizedBox(height: 8),
        Text(switch (_kind) {
          CaptureKind.task =>
            'Escribe o dicta como hablas. Yo pongo fecha, hora y aviso.',
          CaptureKind.project =>
            'Describe el proyecto. Con la IA activa te propongo sus tareas.',
          CaptureKind.goal =>
            'Describe tu meta. La IA la vuelve S.M.A.R.T. y la divide en pasos.',
        }, style: QText.body(context.q.text2).copyWith(fontSize: 13)),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _text,
        autofocus: true,
        enabled: !busy && !listening,
        maxLength: 500,
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: listening
              ? 'Te escucho…'
              : switch (_kind) {
                  CaptureKind.task => '¿Qué hay que hacer?',
                  CaptureKind.project => '¿Qué proyecto?',
                  CaptureKind.goal => '¿Qué quieres lograr?',
                },
          hintText: _hints[_kind],
          suffixIcon: IconButton(
            tooltip: listening ? 'Dejar de dictar' : 'Dictar',
            onPressed: busy
                ? null
                : () => context.read<CaptureBloc>().add(
                    listening
                        ? const CaptureListenStopped()
                        : const CaptureListenRequested(),
                  ),
            icon: Icon(
              listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      QuestlyButton(
        label: busy
            ? (_kind == CaptureKind.task ? 'Entendiendo…' : 'Pensando…')
            : 'Continuar',
        onPressed: busy || listening ? null : _submit,
      ),
      if (widget.onOpenForm case final open?)
        QuestlyButton(
          label: 'Usar el formulario',
          variant: QuestlyButtonVariant.text,
          onPressed: busy || listening ? null : () => open(_kind),
        ),
    ],
  );

  Widget _preview(BuildContext context, CapturePreview state) {
    final q = context.q;
    final bloc = context.read<CaptureBloc>();
    final d = state.draft;
    void edit(TaskDraft next) => bloc.add(CaptureDraftEdited(next));

    final chips = <(String, IconData, VoidCallback)>[
      if (d.dueDate case final due?)
        (
          _day(due),
          Icons.event_outlined,
          () => edit(d.copyWith(dueDate: () => null)),
        ),
      if (d.scheduledAt case final at?)
        (
          'A las ${_time(at)}',
          Icons.schedule,
          () => edit(d.copyWith(scheduledAt: () => null)),
        ),
      if (d.estimatedMinutes case final m?)
        (
          '$m min',
          Icons.timelapse,
          () => edit(d.copyWith(estimatedMinutes: () => null)),
        ),
      if (d.repeatRule case final r?)
        (
          _repeat(r),
          Icons.repeat_rounded,
          () => edit(d.copyWith(repeatRule: () => null)),
        ),
      if (d.reminderMinutes case final r?)
        (
          r == 0 ? 'Aviso a la hora' : 'Aviso $r min antes',
          Icons.notifications_none,
          () => edit(d.copyWith(reminderMinutes: () => null)),
        ),
      if (d.priority == 2)
        (
          'Prioridad alta',
          Icons.priority_high_rounded,
          () => edit(d.copyWith(priority: 0)),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(switch (state.kind) {
          CaptureKind.project => 'Proyecto',
          CaptureKind.goal => 'Meta',
          CaptureKind.task =>
            d.isNote ? 'Parece una nota, no una tarea' : 'Lo que entendí',
        }, style: QText.meta(q.text2)),
        const SizedBox(height: 4),
        Text(d.title, style: QText.title3(q.text)),
        const SizedBox(height: 10),
        // Con hora, se elige si es trabajo o algo puntual que solo debe sonar.
        if (state.kind == CaptureKind.task &&
            !d.isNote &&
            d.scheduledAt != null) ...[
          QuestlySegmented<bool>(
            segments: const [(false, 'Tarea'), (true, 'Recordatorio')],
            selected: d.isReminder,
            onChanged: state.busy
                ? (_) {}
                : (reminder) => edit(d.copyWith(isReminder: reminder)),
          ),
          const SizedBox(height: 6),
          Text(
            d.isReminder
                ? 'Suena a su hora y lo marcas con Hecho. No entra en Foco '
                      'ni da XP.'
                : 'Trabajo para hacer con calma: entra en Foco y da XP.',
            style: QText.meta(q.text2),
          ),
          const SizedBox(height: 10),
        ],
        if (chips.isEmpty)
          Text(
            'Sin fecha ni hora. Puedes ponérsela después.',
            style: QText.body(q.text2),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, icon, remove) in chips)
                InputChip(
                  avatar: Icon(icon, size: 18),
                  label: Text(label),
                  // La meta necesita su fecha (create_goal, 014).
                  onDeleted: state.busy || state.kind == CaptureKind.goal
                      ? null
                      : remove,
                  deleteButtonTooltipMessage: 'Quitar $label',
                ),
            ],
          ),
        if (state.smart case final smart?) ...[
          const SizedBox(height: 14),
          for (final (label, value) in [
            ('Específica', smart.specific),
            ('Medible', smart.measurable),
            ('Alcanzable', smart.achievable),
            ('Relevante', smart.relevant),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: value),
                  ],
                ),
                style: QText.body(q.text),
              ),
            ),
        ],
        if (state.steps.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            state.kind == CaptureKind.task ? 'Pasos' : 'Tareas',
            style: QText.meta(q.text2),
          ),
          for (final step in state.steps)
            SheetRow(
              leading: const SheetCheck(done: false),
              title: step.title,
              subtitle: 'Para el ${_day(step.due).toLowerCase()}',
            ),
        ],
        const SizedBox(height: 6),
        Text(
          state.usedAi ? 'Interpretado con IA' : 'Interpretado con reglas',
          style: QText.meta(q.text2),
        ),
        const SizedBox(height: 14),
        if (!d.isNote && !d.isReminder && state.steps.isEmpty) ...[
          QuestlyButton(
            label: 'Dividir en pasos',
            variant: QuestlyButtonVariant.secondary,
            onPressed: state.busy
                ? null
                : () => bloc.add(const CaptureBreakdownRequested()),
          ),
          const SizedBox(height: 8),
        ],
        QuestlyButton(
          label: state.busy
              ? 'Guardando…'
              : switch (state.kind) {
                  CaptureKind.project => 'Crear proyecto',
                  CaptureKind.goal => 'Crear meta',
                  CaptureKind.task =>
                    d.isNote || widget.preferInbox
                        ? 'Guardar en la Bandeja'
                        : d.isReminder
                        ? 'Crear recordatorio'
                        : 'Crear tarea',
                },
          onPressed: state.busy
              ? null
              : () => bloc.add(CaptureConfirmed(toInbox: widget.preferInbox)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: QuestlyButton(
                label: 'Corregir',
                variant: QuestlyButtonVariant.text,
                onPressed: state.busy
                    ? null
                    : () => bloc.add(const CaptureRestarted()),
              ),
            ),
            if (!d.isNote && state.kind == CaptureKind.task)
              Expanded(
                child: QuestlyButton(
                  label: widget.preferInbox ? 'Crear tarea' : 'A la Bandeja',
                  variant: QuestlyButtonVariant.text,
                  onPressed: state.busy
                      ? null
                      : () => bloc.add(
                          CaptureConfirmed(toInbox: !widget.preferInbox),
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String _day(DateTime d) {
    final now = DateTime.now();
    final days = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    return switch (days) {
      0 => 'Hoy',
      1 => 'Mañana',
      _ => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}',
    };
  }

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  static String _repeat(String rule) {
    const names = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
    final [kind, ...rest] = rule.split(':');
    return switch (kind) {
      'daily' => 'Cada día',
      'weekdays' => 'Lun a vie',
      'weekly' =>
        'Cada ${rest.first.split(',').map((d) => names[int.parse(d)]).join(', ')}',
      'monthly' => 'Cada mes, día ${rest.first}',
      _ => rule,
    };
  }
}
