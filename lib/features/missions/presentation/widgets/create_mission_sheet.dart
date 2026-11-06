import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/domain/entities/new_mission.dart';
import 'package:proyecto_movil/features/missions/presentation/widgets/missions_format.dart';

/// Lo que devuelve la hoja al guardar.
typedef CreateMissionResult = ({NewMission mission, bool startFocus});

class CreateMissionSheet extends StatefulWidget {
  const CreateMissionSheet({super.key, required this.board});

  /// Skills, proyectos y metas del jugador para vincular.
  final MissionsBoard board;

  @override
  State<CreateMissionSheet> createState() => _CreateMissionSheetState();
}

enum _Due { none, today, tomorrow, week, custom }

enum _Repeat { none, daily, weekdays, weekly, monthly }

class _CreateMissionSheetState extends State<CreateMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _checklist = <TextEditingController>[];
  _Due _due = _Due.today;
  DateTime? _customDate;
  MissionPriority _priority = MissionPriority.medium;
  String? _skillId;
  String? _projectId;
  String? _goalId;
  TimeOfDay? _time;
  int _minutes = 30;
  int? _reminder = 10;
  _Repeat _repeat = _Repeat.none;

  int get _xp => MissionsFormat.estimatedXp(
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

  /// Día del bloque y de la repetición: el de la fecha límite o hoy.
  DateTime get _day => _dueDate() ?? DateTime.now();

  DateTime? _scheduledAt() => _time == null
      ? null
      : DateTime(_day.year, _day.month, _day.day, _time!.hour, _time!.minute);

  /// Formato cerrado de `tasks.repeat_rule` (032); domingo = 0 como en SQL.
  String? _repeatRule() => switch (_repeat) {
    _Repeat.none => null,
    _Repeat.daily => 'daily',
    _Repeat.weekdays => 'weekdays',
    _Repeat.weekly => 'weekly:${_day.weekday % 7}',
    _Repeat.monthly => 'monthly:${_day.day}',
  };

  void _save({required bool start}) {
    if (!_formKey.currentState!.validate()) return;
    final hasTime = _time != null;
    final CreateMissionResult result = (
      mission: NewMission(
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
    initialChildSize: .92,
    minChildSize: .65,
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
              'Nueva tarea',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.lq.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Define el siguiente paso y deja que LifeQuest calcule tu recompensa.',
              style: TextStyle(color: context.lq.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _section('TÍTULO'),
            TextFormField(
              controller: _title,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Nombre de la tarea *',
                hintText: 'Preparar presentación del proyecto',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escribe un nombre para la tarea'
                  : null,
            ),
            const SizedBox(height: 8),
            _section('CONTEXTO'),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Contexto de la tarea',
                hintText: 'Detalles, enlaces o notas que te ayuden a hacerla',
              ),
            ),
            const SizedBox(height: 14),
            _section('VINCULAR (OPCIONAL)'),
            Row(
              children: [
                Expanded(
                  child: _linkDropdown(
                    'Área',
                    _skillId,
                    widget.board.skills,
                    (v) => setState(() => _skillId = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _linkDropdown(
                    'Proyecto',
                    _projectId,
                    widget.board.projects,
                    (v) => setState(() => _projectId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _linkDropdown(
              'Meta',
              _goalId,
              widget.board.goals,
              (v) => setState(() => _goalId = v),
            ),
            const SizedBox(height: 14),
            _section('PLANIFICA'),
            Row(
              children: [
                Expanded(
                  child: _dropdown<_Due>('Fecha límite', _due, const {
                    _Due.none: 'Sin fecha',
                    _Due.today: 'Hoy',
                    _Due.tomorrow: 'Mañana',
                    _Due.week: 'Esta semana',
                    _Due.custom: 'Personalizada',
                  }, (v) => setState(() => _due = v!)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dropdown<MissionPriority>('Prioridad', _priority, {
                    for (final p in MissionPriority.values.reversed)
                      p: MissionsFormat.priority(p),
                  }, (v) => setState(() => _priority = v!)),
                ),
              ],
            ),
            if (_due == _Due.custom)
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _customDate == null
                      ? 'Elegir fecha personalizada'
                      : 'Vence el ${_customDate!.day}/${_customDate!.month}/${_customDate!.year}',
                ),
              ),
            const SizedBox(height: 14),
            _section('AGENDA'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _time == null
                          ? 'Sin hora'
                          : 'A las ${_time!.format(context)}',
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
                    child: _dropdown<int>('Duración', _minutes, const {
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
                    child: _dropdown<int?>('Aviso', _reminder, const {
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
            const SizedBox(height: 8),
            _dropdown<_Repeat>('Repetir', _repeat, {
              _Repeat.none: 'No se repite',
              _Repeat.daily: 'Cada día',
              _Repeat.weekdays: 'De lunes a viernes',
              _Repeat.weekly: 'Cada ${MissionsFormat.weekday(_day)}',
              _Repeat.monthly: 'Cada mes, el día ${_day.day}',
            }, (v) => setState(() => _repeat = v!)),
            const SizedBox(height: 14),
            _section('SUBTAREAS (OPCIONAL)'),
            for (var i = 0; i < _checklist.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _checklist[i],
                        decoration: InputDecoration(
                          hintText: 'Subtarea ${i + 1}',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar subtarea ${i + 1}',
                      onPressed: () => setState(() {
                        _checklist[i].dispose();
                        _checklist.removeAt(i);
                      }),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _checklist.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Añadir subtarea'),
              ),
            ),
            const SizedBox(height: 8),
            LifeQuestSurface(
              color: context.lq.softGreen,
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: context.lq.deepGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECOMPENSA ESTIMADA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: context.lq.deepGreen,
                          ),
                        ),
                        Text(
                          '$_xp XP',
                          style: TextStyle(
                            color: context.lq.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _save(start: false),
                icon: const Icon(Icons.check),
                label: const Text('Crear tarea'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _save(start: true),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Crear e iniciar Focus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.lq.deepGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: TextStyle(
        color: context.lq.deepGreen,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _linkDropdown(
    String label,
    String? value,
    List<MissionLink> links,
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
    if (date != null && mounted) setState(() => _customDate = date);
  }
}
