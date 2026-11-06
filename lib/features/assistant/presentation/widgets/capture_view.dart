import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';

/// Contenido de la hoja «Anotar»: escribir, revisar los chips y confirmar.
/// Al guardar cierra la hoja con `true`.
class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  final _text = TextEditingController();

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
        (s is CapturePreview && s.message != null) ||
        (s is CaptureWriting && s.message != null),
    listener: (context, state) => switch (state) {
      CaptureSaved() => Navigator.pop(context, true),
      CapturePreview(:final message?) ||
      CaptureWriting(:final message?) => showLifeQuestMessage(context, message),
      _ => null,
    },
    builder: (context, state) => switch (state) {
      CaptureWriting(:final busy) => _writing(busy),
      CapturePreview() => _preview(context, state),
      CaptureSaved() => const SizedBox(height: 120),
    },
  );

  Widget _writing(bool busy) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _text,
        autofocus: true,
        enabled: !busy,
        maxLength: 500,
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: '¿Qué tienes en mente?',
          hintText: 'gym mañana 6pm cada lunes',
        ),
      ),
      const SizedBox(height: 12),
      QuestlyButton(
        label: busy ? 'Entendiendo…' : 'Continuar',
        onPressed: busy ? null : _submit,
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
        Text(
          d.isNote ? 'Parece una nota, no una tarea' : 'Lo que entendí',
          style: QText.meta(q.text2),
        ),
        const SizedBox(height: 4),
        Text(d.title, style: QText.title3(q.text)),
        const SizedBox(height: 10),
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
                  onDeleted: state.busy ? null : remove,
                  deleteButtonTooltipMessage: 'Quitar $label',
                ),
            ],
          ),
        if (state.steps.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Pasos', style: QText.meta(q.text2)),
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
        if (!d.isNote && state.aiAvailable && state.steps.isEmpty) ...[
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
              : d.isNote
              ? 'Guardar en la Bandeja'
              : 'Crear tarea',
          onPressed: state.busy
              ? null
              : () => bloc.add(const CaptureConfirmed()),
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
            if (!d.isNote)
              Expanded(
                child: QuestlyButton(
                  label: 'A la Bandeja',
                  variant: QuestlyButtonVariant.text,
                  onPressed: state.busy
                      ? null
                      : () => bloc.add(const CaptureConfirmed(toInbox: true)),
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
