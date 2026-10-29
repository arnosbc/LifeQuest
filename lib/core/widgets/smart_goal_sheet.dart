import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/entities/smart_goal.dart';

/// Alta de Meta con el formulario S.M.A.R.T.; devuelve [SmartGoal] al
/// guardar. La usan Stage (Quick Add) y el Brain Dump (G.T.D. → Meta).
class SmartGoalSheet extends StatefulWidget {
  const SmartGoalSheet({
    super.key,
    required this.skills,
    this.initialTitle = '',
  });

  final List<SkillChoice> skills;

  /// Nombre ya escrito, p. ej. la idea que venía del Brain Dump.
  final String initialTitle;

  @override
  State<SmartGoalSheet> createState() => _SmartGoalSheetState();
}

class _SmartGoalSheetState extends State<SmartGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  final _specific = TextEditingController();
  final _measurable = TextEditingController();
  final _achievable = TextEditingController();
  final _relevant = TextEditingController();
  final _timebound = TextEditingController();
  DateTime? _dueDate;
  String? _skillId;
  bool _missingDate = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _specific,
      _measurable,
      _achievable,
      _relevant,
      _timebound,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 1825)),
      initialDate: _dueDate ?? now.add(const Duration(days: 90)),
    );
    if (date != null && mounted) {
      setState(() {
        _dueDate = date;
        _missingDate = false;
      });
    }
  }

  void _save() {
    final valid = _formKey.currentState!.validate();
    setState(() => _missingDate = _dueDate == null);
    if (!valid || _dueDate == null) return;
    Navigator.pop(
      context,
      SmartGoal(
        title: _title.text.trim(),
        specific: _specific.text.trim(),
        measurable: _measurable.text.trim(),
        achievable: _achievable.text.trim(),
        relevant: _relevant.text.trim(),
        dueDate: _dueDate!,
        timebound: _timebound.text.trim(),
        skillId: _skillId,
      ),
    );
  }

  Widget _smart(
    TextEditingController controller,
    String letter,
    String label,
    String hint,
  ) => TextFormField(
    controller: controller,
    maxLines: 2,
    minLines: 1,
    decoration: InputDecoration(
      labelText: '$letter · $label *',
      hintText: hint,
    ),
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'Responde esta pregunta' : null,
  );

  /// Todas las skills a la vista como chips (un desplegable las escondía).
  Widget _skillPicker(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Text(
        'Área / skill',
        style: TextStyle(
          color: context.lq.ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Sin vincular'),
            selected: _skillId == null,
            onSelected: (_) => setState(() => _skillId = null),
          ),
          for (final skill in widget.skills)
            ChoiceChip(
              label: Text(skill.name),
              selected: _skillId == skill.id,
              onSelected: (_) => setState(() => _skillId = skill.id),
            ),
        ],
      ),
      if (widget.skills.isEmpty)
        Text(
          'Aún no tienes skills. Créalas en tu Perfil para vincular tus metas.',
          style: TextStyle(color: context.lq.muted, fontSize: 12),
        ),
    ],
  );

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
          // Aire uniforme entre campos: con los textos de error y de ayuda
          // no se montan unos sobre otros.
          spacing: 16,
          children: [
            Text(
              'Nueva meta S.M.A.R.T.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.lq.ink,
              ),
            ),
            TextFormField(
              controller: _title,
              autofocus: widget.initialTitle.isEmpty,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Nombre de la meta *',
                hintText: 'Correr 10 km',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escribe un nombre para la meta'
                  : null,
            ),
            _smart(
              _specific,
              'S',
              '¿Qué exactamente quieres lograr?',
              'Correr 10 km sin parar',
            ),
            _smart(
              _measurable,
              'M',
              '¿Cómo sabrás que lo lograste?',
              'Terminar en menos de 60 minutos',
            ),
            _smart(
              _achievable,
              'A',
              '¿Por qué es alcanzable?',
              'Entreno 3 veces por semana',
            ),
            _smart(
              _relevant,
              'R',
              '¿Por qué te importa?',
              'Quiero tener más energía',
            ),
            // El mensaje de error va pegado a su botón, no a 16 px.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _dueDate == null
                          ? 'T · Fecha límite *'
                          : 'T · Vence el ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                    ),
                  ),
                ),
                if (_missingDate)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      'Elige una fecha límite',
                      style: TextStyle(color: context.lq.error, fontSize: 12),
                    ),
                  ),
              ],
            ),
            TextFormField(
              controller: _timebound,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Hitos o plazos intermedios (opcional)',
              ),
            ),
            _skillPicker(context),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Crear meta'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
