import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;

import 'package:proyecto_movil/core/errors/failures.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';
import 'package:proyecto_movil/features/tasks/presentation/widgets/tasks_format.dart';

/// Lo que devuelve la hoja al guardar.
typedef CreateTaskResult = ({NewTask task, bool startFocus});

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({
    super.key,
    required this.board,
    this.initial,
    this.suggestSteps,
  });

  /// La IA propone los pasos a partir del título; null oculta el botón.
  final Future<Either<Failure, List<String>>> Function(String title)?
  suggestSteps;

  /// Skills, proyectos y metas del jugador para vincular.
  final TasksBoard board;

  /// Tarea a editar; null = crear. Al editar no se cambian vínculos ni
  /// subtareas.
  final Task? initial;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

enum _Due { none, today, tomorrow, week, custom }

enum _Repeat { none, daily, weekdays, weekly, monthly }

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _checklist = <TextEditingController>[];
  _Due _due = _Due.today;
  DateTime? _customDate;
  TaskPriority _priority = TaskPriority.medium;
  String? _skillId;
  String? _projectId;
  String? _goalId;
  TimeOfDay? _time;
  int _minutes = 30;
  int? _reminder = 10;
  _Repeat _repeat = _Repeat.none;

  /// «Más opciones» abierto; al editar se abre si la tarea ya usa algo de ahí.
  bool _more = false;

  /// Regla original al editar: se conserva si no se cambia el tipo (p. ej.
  /// «weekly:1,3» no se reduce a un solo día).
  String? _originalRule;

  bool get _editing => widget.initial != null;

  /// Pidiendo los pasos a la IA.
  bool _suggesting = false;
  String? _stepsError;

  int get _xp => TasksFormat.estimatedXp(
    title: _title.text,
    priority: _priority,
    hasGoal: _goalId != null,
    hasProject: _projectId != null,
  );

  @override
  void initState() {
    super.initState();
    // La vista previa de la recompensa depende de las palabras del título.
    _title.addListener(() => setState(() {}));
    if (widget.initial case final m?) {
      _title.text = m.title;
      _description.text = m.description ?? '';
      _priority = m.priority;
      _due = m.dueDate == null ? _Due.none : _Due.custom;
      _customDate = m.dueDate;
      _time = m.scheduledAt == null
          ? null
          : TimeOfDay.fromDateTime(m.scheduledAt!);
      _minutes = m.estimatedMinutes ?? 30;
      _reminder = m.scheduledAt == null ? 10 : m.reminderMinutes;
      _originalRule = m.repeatRule;
      _repeat = switch (m.repeatRule?.split(':').first) {
        'daily' => _Repeat.daily,
        'weekdays' => _Repeat.weekdays,
        'weekly' => _Repeat.weekly,
        'monthly' => _Repeat.monthly,
        _ => _Repeat.none,
      };
      _more =
          m.scheduledAt != null ||
          m.repeatRule != null ||
          (m.description ?? '').isNotEmpty;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final item in _checklist) {
      item.dispose();
    }
    super.dispose();
  }

  /// Fin del día elegido (23:59 hora local); "Esta semana" vence el domingo.
  DateTime? _dueDate() {
    final now = DateTime.now();
    DateTime endOf(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59);
    return switch (_due) {
      _Due.none => null,
      _Due.today => endOf(now),
      _Due.tomorrow => endOf(now.add(const Duration(days: 1))),
      _Due.week => endOf(
        now.add(Duration(days: DateTime.sunday - now.weekday)),
      ),
      _Due.custom => _customDate == null ? null : endOf(_customDate!),
    };
  }

  /// Día del bloque y de la repetición: el de la fecha límite, el del bloque
  /// que ya tenía (al editar) o hoy.
  DateTime get _day =>
      _dueDate() ?? widget.initial?.scheduledAt ?? DateTime.now();

  DateTime? _scheduledAt() => _time == null
      ? null
      : DateTime(_day.year, _day.month, _day.day, _time!.hour, _time!.minute);

  /// Formato cerrado de `tasks.repeat_rule` (032); domingo = 0 como en SQL.
  String? _repeatRule() {
    final original = _originalRule;
    if (original != null && original.startsWith(_repeat.name)) return original;
    return _newRepeatRule();
  }

  String? _newRepeatRule() => switch (_repeat) {
    _Repeat.none => null,
    _Repeat.daily => 'daily',
    _Repeat.weekdays => 'weekdays',
    _Repeat.weekly => 'weekly:${_day.weekday % 7}',
    _Repeat.monthly => 'monthly:${_day.day}',
  };

  void _save({required bool start}) {
    if (!_formKey.currentState!.validate()) return;
    final hasTime = _time != null;
    final CreateTaskResult result = (
      task: NewTask(
        title: _title.text.trim(),
        description: _description.text.trim(),
        priority: _priority,
        dueDate: _dueDate(),
        skillId: _skillId,
        projectId: _projectId,
        goalId: _goalId,
        subtasks: [
          for (final item in _checklist)
            if (item.text.trim().isNotEmpty) item.text.trim(),
        ],
        scheduledAt: _scheduledAt(),
        estimatedMinutes: hasTime ? _minutes : null,
        reminderMinutes: hasTime ? _reminder : null,
        repeatRule: _repeatRule(),
      ),
      startFocus: start,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: _more ? .92 : .62,
    minChildSize: .5,
    maxChildSize: .96,
    expand: false,
    builder: (context, scrollController) => Container(
      decoration: BoxDecoration(
        color: context.lq.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.lq.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _editing ? 'Editar tarea' : 'Nueva tarea',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.lq.ink,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              autofocus: !_editing,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: '¿Qué hay que hacer?',
                counterText: '',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escribe un nombre para la tarea'
                  : null,
            ),
            const SizedBox(height: 16),
            _section('PARA CUÁNDO'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (due, label) in const [
                  (_Due.today, 'Hoy'),
                  (_Due.tomorrow, 'Mañana'),
                  (_Due.week, 'Esta semana'),
                  (_Due.none, 'Sin fecha'),
                ])
                  QuestlyFilterChip(
                    label: label,
                    selected: _due == due,
                    onTap: () => setState(() => _due = due),
                  ),
                QuestlyFilterChip(
                  label: _due == _Due.custom && _customDate != null
                      ? '${_customDate!.day}/${_customDate!.month}'
                      : 'Otro día',
                  selected: _due == _Due.custom,
                  onTap: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section('PRIORIDAD'),
            QuestlySegmented<TaskPriority>(
              segments: [
                for (final p in TaskPriority.values)
                  (p, TasksFormat.priority(p)),
              ],
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            if (!_editing) ..._steps(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _more = !_more),
                icon: Icon(_more ? Icons.expand_less : Icons.expand_more),
                label: Text(
                  _more ? 'Menos opciones' : 'Hora, aviso, repetir y más',
                ),
              ),
            ),
            if (_more) ..._moreOptions(context),
            const SizedBox(height: 8),
            Text(
              'Ganarás $_xp XP al completarla.',
              style: TextStyle(color: context.lq.muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => _save(start: false),
                child: Text(_editing ? 'Guardar cambios' : 'Crear tarea'),
              ),
            ),
            if (!_editing)
              TextButton.icon(
                onPressed: () => _save(start: true),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Crear y empezar foco'),
              ),
          ],
        ),
      ),
    ),
  );

  /// Lo opcional, plegado para que crear sea rápido.
  List<Widget> _moreOptions(BuildContext context) => [
    _section('HORA'),
    Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text(
              _time == null ? 'Sin hora' : 'A las ${_time!.format(context)}',
            ),
          ),
        ),
        if (_time != null)
          IconButton(
            tooltip: 'Quitar la hora',
            onPressed: () => setState(() => _time = null),
            icon: const Icon(Icons.close),
          ),
      ],
    ),
    if (_time != null) ...[
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _dropdown<int>('Duración', _minutes, {
              _minutes: '$_minutes min',
              15: '15 min',
              30: '30 min',
              45: '45 min',
              60: '1 h',
              90: '1 h 30',
              120: '2 h',
            }, (v) => setState(() => _minutes = v!)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dropdown<int?>('Aviso', _reminder, {
              ?_reminder: '$_reminder min antes',
              null: 'Sin aviso',
              0: 'A la hora',
              5: '5 min antes',
              10: '10 min antes',
              30: '30 min antes',
              60: '1 h antes',
            }, (v) => setState(() => _reminder = v)),
          ),
        ],
      ),
    ],
    const SizedBox(height: 12),
    _dropdown<_Repeat>('Repetir', _repeat, {
      _Repeat.none: 'No se repite',
      _Repeat.daily: 'Cada día',
      _Repeat.weekdays: 'De lunes a viernes',
      _Repeat.weekly: _originalRule?.startsWith('weekly') ?? false
          ? TasksFormat.repeat(_originalRule)!
          : 'Cada ${TasksFormat.weekday(_day)}',
      _Repeat.monthly: 'Cada mes, el día ${_day.day}',
    }, (v) => setState(() => _repeat = v!)),
    const SizedBox(height: 12),
    TextFormField(
      controller: _description,
      maxLines: 3,
      minLines: 1,
      decoration: const InputDecoration(
        labelText: 'Notas',
        hintText: 'Detalles o enlaces que te ayuden',
      ),
    ),
    if (!_editing) ...[
      const SizedBox(height: 16),
      _section('VINCULAR'),
      _linkDropdown(
        'Área',
        _skillId,
        widget.board.skills,
        (v) => setState(() => _skillId = v),
      ),
      const SizedBox(height: 8),
      _linkDropdown(
        'Proyecto',
        _projectId,
        widget.board.projects,
        (v) => setState(() => _projectId = v),
      ),
      const SizedBox(height: 8),
      _linkDropdown(
        'Meta',
        _goalId,
        widget.board.goals,
        (v) => setState(() => _goalId = v),
      ),
    ],
  ];

  /// Pasos (subtareas): los propone la IA o se escriben a mano.
  List<Widget> _steps() => [
    const SizedBox(height: 16),
    _section('PASOS'),
    for (var i = 0; i < _checklist.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _checklist[i],
                decoration: InputDecoration(hintText: 'Paso ${i + 1}'),
              ),
            ),
            IconButton(
              tooltip: 'Quitar paso ${i + 1}',
              onPressed: () => setState(() {
                _checklist[i].dispose();
                _checklist.removeAt(i);
              }),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    if (_stepsError case final error?)
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(error, style: TextStyle(color: context.lq.muted)),
      ),
    Wrap(
      spacing: 4,
      children: [
        if (widget.suggestSteps != null && _checklist.isEmpty)
          TextButton.icon(
            onPressed: _suggesting ? null : _suggest,
            icon: _suggesting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(
              _suggesting ? 'Pensando los pasos…' : 'Dividir en pasos',
            ),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        TextButton.icon(
          onPressed: () =>
              setState(() => _checklist.add(TextEditingController())),
          icon: const Icon(Icons.add),
          label: const Text('Añadir paso'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ],
    ),
  ];

  Future<void> _suggest() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _stepsError = 'Escribe primero qué hay que hacer.');
      return;
    }
    setState(() {
      _suggesting = true;
      _stepsError = null;
    });
    final result = await widget.suggestSteps!(title);
    if (!mounted) return;
    setState(() {
      _suggesting = false;
      result.match((f) => _stepsError = f.message, (steps) {
        for (final step in steps) {
          _checklist.add(TextEditingController(text: step));
        }
      });
    });
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        color: context.lq.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
    ),
  );

  Widget _linkDropdown(
    String label,
    String? value,
    List<TaskLink> links,
    ValueChanged<String?> onChanged,
  ) => _dropdown<String?>(label, value, {
    null: 'Sin vincular',
    for (final link in links) link.id: link.name,
  }, onChanged);

  Widget _dropdown<T>(
    String label,
    T value,
    Map<T, String> items,
    ValueChanged<T?> onChanged,
  ) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final MapEntry(:key, value: text) in items.entries)
        DropdownMenuItem<T>(
          value: key,
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime:
          _time ??
          TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(hours: 1)),
          ).replacing(minute: 0),
    );
    if (time != null && mounted) setState(() => _time = time);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _customDate ?? now,
    );
    if (date != null && mounted) {
      setState(() {
        _customDate = date;
        _due = _Due.custom;
      });
    }
  }
}
