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

class _CreateMissionSheetState extends State<CreateMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _natural = TextEditingController();
  final _checklist = <TextEditingController>[];
  _Due _due = _Due.today;
  DateTime? _customDate;
  MissionPriority _priority = MissionPriority.medium;
  String? _skillId;
  String? _projectId;
  String? _goalId;

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
    _natural.dispose();
    for (final item in _checklist) {
      item.dispose();
    }
    super.dispose();
  }

  void _interpret() {
    final text = _natural.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (_title.text.trim().isEmpty) _title.text = text;
      if (_description.text.trim().isEmpty) {
        _description.text = 'Completar: $text';
      }
      if (text.toLowerCase().contains('viernes')) _due = _Due.week;
    });
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

  void _save({required bool start}) {
    if (!_formKey.currentState!.validate()) return;
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
              'Nueva misión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.lq.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Define el siguiente paso y deja que LifeQuest calcule tu recompensa.',
              style: TextStyle(color: context.lq.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _section('¿QUÉ NECESITAS LOGRAR?'),
            TextField(
              controller: _natural,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _interpret(),
              decoration: InputDecoration(
                hintText: 'Ej. Preparar la exposición del viernes',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Convertir en misión',
                  onPressed: _interpret,
                ),
                helperText:
                    'Escribe una idea y toca ✨ para completar un borrador.',
              ),
            ),
            const SizedBox(height: 10),
            _section('DEFINE LA MISIÓN'),
            TextFormField(
              controller: _title,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Nombre de la misión *',
                hintText: 'Preparar presentación del proyecto',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escribe un nombre para la misión'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '¿Qué significa completarla? *',
                hintText: 'Criterio de éxito o resultado esperado',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Describe brevemente el resultado esperado'
                  : null,
            ),
            const SizedBox(height: 14),
            _section('VINCULAR (OPCIONAL)'),
            Row(
              children: [
                Expanded(
                  child: _linkDropdown(
                    'Área / skill',
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
              'Meta (cada misión le resta vida al jefe)',
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
                            fontWeight: FontWeight.w800,
                            color: context.lq.deepGreen,
                          ),
                        ),
                        Text(
                          '$_xp XP · ${MissionsFormat.estimatedCoins(_xp)} monedas',
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
                label: const Text('Crear misión'),
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
        fontWeight: FontWeight.w800,
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
