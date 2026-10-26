import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';

/// Alta de un hábito; devuelve [NewHabit] al guardar.
class CreateHabitSheet extends StatefulWidget {
  const CreateHabitSheet({super.key, required this.type, required this.skills});

  /// Tipo de la pestaña desde la que se abrió.
  final HabitType type;
  final List<HabitSkill> skills;

  @override
  State<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<CreateHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late HabitType _type = widget.type;
  final Set<int> _days = {};
  int _severity = 5;
  String? _skillId;

  // Orden de lunes a domingo; el valor es 0 = domingo … 6 = sábado.
  static const _week = [
    (1, 'L', 'lunes'),
    (2, 'M', 'martes'),
    (3, 'X', 'miércoles'),
    (4, 'J', 'jueves'),
    (5, 'V', 'viernes'),
    (6, 'S', 'sábado'),
    (0, 'D', 'domingo'),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      NewHabit(
        name: _name.text.trim(),
        type: _type,
        specificDays: _type == HabitType.good ? (_days.toList()..sort()) : [],
        hpPenalty: _type == HabitType.bad ? _severity : 0,
        skillId: _skillId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: LifeQuestColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nuevo hábito',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: LifeQuestColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<HabitType>(
              segments: const [
                ButtonSegment(value: HabitType.good, label: Text('Bueno')),
                ButtonSegment(value: HabitType.bad, label: Text('Por evitar')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              maxLength: 100,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nombre del hábito *',
                hintText: _type == HabitType.good
                    ? 'Leer 10 páginas'
                    : 'Pantallas antes de dormir',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escribe un nombre para el hábito'
                  : null,
            ),
            const SizedBox(height: 8),
            if (_type == HabitType.good) ...[
              const Text(
                '¿Qué días? (ninguno = todos los días)',
                style: TextStyle(color: LifeQuestColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (value, letter, name) in _week)
                    Semantics(
                      label: name,
                      excludeSemantics: true,
                      selected: _days.contains(value),
                      child: FilterChip(
                        label: Text(letter),
                        selected: _days.contains(value),
                        onSelected: (on) => setState(
                          () => on ? _days.add(value) : _days.remove(value),
                        ),
                      ),
                    ),
                ],
              ),
            ] else ...[
              const Text(
                '¿Cuánto te afecta? Cada registro resta esa vida.',
                style: TextStyle(color: LifeQuestColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('Leve −3')),
                  ButtonSegment(value: 5, label: Text('Media −5')),
                  ButtonSegment(value: 8, label: Text('Grave −8')),
                ],
                selected: {_severity},
                onSelectionChanged: (s) => setState(() => _severity = s.first),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _skillId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Área / skill'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sin vincular'),
                ),
                for (final skill in widget.skills)
                  DropdownMenuItem(
                    value: skill.id,
                    child: Text(skill.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _skillId = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Crear hábito'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
