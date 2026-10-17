import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';
import '../models/mission.dart';

class CreateMissionSheet extends StatefulWidget {
  const CreateMissionSheet({super.key});

  @override
  State<CreateMissionSheet> createState() => _CreateMissionSheetState();
}

class _CreateMissionSheetState extends State<CreateMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _natural = TextEditingController();
  final _checklist = <TextEditingController>[];
  String _due = 'Hoy';
  String _duration = '30 min';
  String _priority = 'Media';
  String? _area;
  String? _project;
  String? _goal;
  bool _highlight = false;
  bool _startFocus = false;
  int get _xp => (80 + _durationXp + _priorityXp + _checklist.length * 15);
  int get _durationXp => switch (_duration) { '15 min' => 20, '30 min' => 45, '1 h' => 80, '2 h' => 130, _ => 45 };
  int get _priorityXp => switch (_priority) { 'Baja' => 0, 'Media' => 25, 'Alta' => 55, 'Crítica' => 85, _ => 25 };

  @override
  void dispose() {
    _title.dispose(); _description.dispose(); _natural.dispose();
    for (final item in _checklist) { item.dispose(); }
    super.dispose();
  }

  void _interpret() {
    final text = _natural.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (_title.text.trim().isEmpty) _title.text = text;
      if (_description.text.trim().isEmpty) _description.text = 'Completar: $text';
      if (text.toLowerCase().contains('viernes')) _due = 'Esta semana';
    });
  }

  void _save({required bool start}) {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, Mission(
      title: _title.text.trim(), description: _description.text.trim(), due: _due,
      duration: _duration, priority: _priority, xp: _xp,
      coins: (_xp * .32).round(), started: start, highlight: _highlight,
    ));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .92, minChildSize: .65, maxChildSize: .96,
    expand: false,
    builder: (context, scrollController) => Container(
      decoration: const BoxDecoration(color: LifeQuestColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      child: Form(key: _formKey, child: ListView(controller: scrollController, padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.viewInsetsOf(context).bottom), children: [
        Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: LifeQuestColors.line, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 15),
        const Text('Nueva misión', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: LifeQuestColors.ink)),
        const SizedBox(height: 4),
        const Text('Define el siguiente paso y deja que LifeQuest calcule tu recompensa.', style: TextStyle(color: LifeQuestColors.muted, fontSize: 12)),
        const SizedBox(height: 16),
        _section('¿QUÉ NECESITAS LOGRAR?'),
        TextField(controller: _natural, textInputAction: TextInputAction.done, onSubmitted: (_) => _interpret(), decoration: InputDecoration(hintText: 'Ej. Preparar la exposición del viernes', suffixIcon: IconButton(icon: const Icon(Icons.auto_awesome), tooltip: 'Convertir en misión', onPressed: _interpret), helperText: 'Escribe una idea y toca ✨ para completar un borrador.')),
        const SizedBox(height: 10),
        _section('DEFINE LA MISIÓN'),
        TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Nombre de la misión *', hintText: 'Preparar presentación del proyecto'), validator: (v) => v == null || v.trim().isEmpty ? 'Escribe un nombre para la misión' : null),
        const SizedBox(height: 8),
        TextFormField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: '¿Qué significa completarla? *', hintText: 'Criterio de éxito o resultado esperado'), validator: (v) => v == null || v.trim().isEmpty ? 'Describe brevemente el resultado esperado' : null),
        const SizedBox(height: 14),
        _section('VINCULAR (OPCIONAL)'),
        Row(children: [
          Expanded(child: _dropdown<String?>('Área / skill', _area, [null, 'Estudio', 'Trabajo', 'Salud', 'Personal'], (v) => setState(() { _area = v; _project = null; _goal = null; }))),
          const SizedBox(width: 8),
          Expanded(child: _dropdown<String?>('Proyecto', _project, [null, if (_area == 'Estudio') 'Curso actual', if (_area == 'Trabajo') 'Proyecto actual', if (_area == 'Personal') 'Desarrollo personal'], (v) => setState(() { _project = v; _goal = null; }))),
        ]),
        if (_project != null) ...[const SizedBox(height: 8), _dropdown<String?>('Meta', _goal, [null, 'Completar el objetivo del proyecto', 'Avanzar esta semana'], (v) => setState(() => _goal = v))],
        const SizedBox(height: 14),
        _section('PLANIFICA'),
        Row(children: [Expanded(child: _dropdown<String>('Fecha límite', _due, const ['Hoy', 'Mañana', 'Esta semana', 'Personalizada'], (v) => setState(() => _due = v!))), const SizedBox(width: 8), Expanded(child: _dropdown<String>('Duración', _duration, const ['15 min', '30 min', '1 h', '2 h'], (v) => setState(() => _duration = v!)))]),
        if (_due == 'Personalizada') TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month), label: const Text('Elegir fecha personalizada')),
        const SizedBox(height: 8),
        _dropdown<String>('Prioridad', _priority, const ['Baja', 'Media', 'Alta', 'Crítica'], (v) => setState(() => _priority = v!)),
        const SizedBox(height: 14),
        _section('SUBTAREAS (OPCIONAL)'),
        for (var i = 0; i < _checklist.length; i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Expanded(child: TextField(controller: _checklist[i], decoration: InputDecoration(hintText: 'Subtarea ${i + 1}'))), IconButton(onPressed: () => setState(() { _checklist[i].dispose(); _checklist.removeAt(i); }), icon: const Icon(Icons.close))])),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _checklist.add(TextEditingController())), icon: const Icon(Icons.add), label: const Text('Añadir subtarea'))),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Daily Highlight'), subtitle: const Text('Marcar como mi avance principal de hoy'), value: _highlight, onChanged: (v) => setState(() => _highlight = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Iniciar sesión Focus'), subtitle: const Text('Abrir una sesión de concentración al crearla'), value: _startFocus, onChanged: (v) => setState(() => _startFocus = v)),
        const SizedBox(height: 8),
        LifeQuestSurface(color: const Color(0xFFEDFBF2), child: Row(children: [const Icon(Icons.auto_awesome, color: LifeQuestColors.deepGreen), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('RECOMPENSA ESTIMADA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: LifeQuestColors.deepGreen)), Text('$_xp XP · ${(_xp * .32).round()} monedas · Dificultad ${_priority == 'Baja' ? 'fácil' : _priority == 'Crítica' ? 'alta' : 'media'}', style: const TextStyle(color: LifeQuestColors.ink, fontWeight: FontWeight.w700, fontSize: 12))]))])),
        const SizedBox(height: 14),
        SizedBox(height: 46, child: FilledButton.icon(onPressed: () => _save(start: false), icon: const Icon(Icons.check), label: const Text('Crear misión'))),
        const SizedBox(height: 8),
        SizedBox(height: 46, child: OutlinedButton.icon(onPressed: () => _save(start: true), icon: const Icon(Icons.play_arrow), label: const Text('Crear e iniciar Focus'), style: OutlinedButton.styleFrom(foregroundColor: LifeQuestColors.deepGreen))),
      ])),
    ),
  );

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(title, style: const TextStyle(color: LifeQuestColors.deepGreen, fontSize: 10, fontWeight: FontWeight.w800)));

  Widget _dropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [for (final item in items) DropdownMenuItem<T>(value: item, child: Text(item?.toString() ?? 'Sin vincular', overflow: TextOverflow.ellipsis))],
    onChanged: onChanged,
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now());
    if (date != null && mounted) setState(() => _due = '${date.day}/${date.month}/${date.year}');
  }
}
