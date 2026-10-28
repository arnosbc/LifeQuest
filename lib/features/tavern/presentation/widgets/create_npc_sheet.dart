import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';

/// Alta de un NPC; devuelve [NewNpc] al guardar. La skill es obligatoria.
class CreateNpcSheet extends StatefulWidget {
  const CreateNpcSheet({super.key, required this.skills});

  final List<TavernSkill> skills;

  @override
  State<CreateNpcSheet> createState() => _CreateNpcSheetState();
}

class _CreateNpcSheetState extends State<CreateNpcSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mission = TextEditingController();
  NpcFrequency _frequency = NpcFrequency.weekly;
  String? _skillId;

  @override
  void dispose() {
    _name.dispose();
    _mission.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      NewNpc(
        name: _name.text.trim(),
        skillId: _skillId!,
        frequency: _frequency,
        nobleMission: _mission.text.trim().isEmpty
            ? null
            : _mission.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
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
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nuevo NPC',
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Un personaje que te pedirá misiones de una de tus skills.',
              style: TextStyle(color: context.lq.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre y papel'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Ponle un nombre.' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _skillId,
              decoration: const InputDecoration(labelText: 'Skill que entrena'),
              items: [
                for (final s in widget.skills)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _skillId = v),
              validator: (v) => v == null ? 'Elige una skill.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mission,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Noble misión (opcional)',
                hintText: 'Ej.: que entrenes sin lesionarte',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Cada cuánto te visita?',
              style: TextStyle(color: context.lq.ink, fontSize: 13),
            ),
            const SizedBox(height: 6),
            SegmentedButton<NpcFrequency>(
              segments: const [
                ButtonSegment(value: NpcFrequency.daily, label: Text('Diario')),
                ButtonSegment(
                  value: NpcFrequency.weekly,
                  label: Text('Semanal'),
                ),
                ButtonSegment(
                  value: NpcFrequency.monthly,
                  label: Text('Mensual'),
                ),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) => setState(() => _frequency = s.first),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Invitar a la Taverna'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
