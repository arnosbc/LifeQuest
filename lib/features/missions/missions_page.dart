import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

class _Mission {
  const _Mission({
    required this.title,
    required this.description,
    required this.due,
    required this.duration,
    required this.priority,
    required this.xp,
    required this.coins,
    this.started = false,
    this.highlight = false,
  });

  final String title;
  final String description;
  final String due;
  final String duration;
  final String priority;
  final int xp;
  final int coins;
  final bool started;
  final bool highlight;

  _Mission copyWith({bool? started}) => _Mission(
    title: title,
    description: description,
    due: due,
    duration: duration,
    priority: priority,
    xp: xp,
    coins: coins,
    started: started ?? this.started,
    highlight: highlight,
  );
}

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  final List<_Mission> _missions = [
    const _Mission(
      title: 'Leer 20 páginas', description: 'Avanzar en el libro actual',
      due: 'Hoy', duration: '30 min', priority: 'Media', xp: 120, coins: 40,
    ),
    const _Mission(
      title: 'Salir a caminar', description: 'Dar un paseo al aire libre',
      due: 'Hoy', duration: '30 min', priority: 'Media', xp: 180, coins: 60,
    ),
    const _Mission(
      title: 'Planificar la semana', description: 'Organizar prioridades y agenda',
      due: 'Mañana', duration: '1 h', priority: 'Baja', xp: 200, coins: 70,
    ),
  ];
  bool _started = false;

  Future<void> _createMission() async {
    final result = await showModalBottomSheet<_Mission>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateMissionSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _missions.insert(0, result);
      if (result.highlight) _missions.removeWhere((m) => m != result && m.highlight);
      _started = result.started;
    });
    showLifeQuestMessage(context, result.started
        ? 'Misión creada. ¡Sesión de enfoque lista!'
        : 'Misión creada. ¡Un paso más hacia tu objetivo!');
  }

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Misiones',
    subtitle: 'Cada paso cuenta para tu siguiente nivel.',
    children: [
      const LifeQuestSurface(
        child: Row(children: [
          LifeQuestIconTile(Icons.auto_awesome),
          SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GENIE DE RP', style: TextStyle(color: LifeQuestColors.deepGreen, fontSize: 10, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('He revisado tu campaña, objetivos y plazos. Esta es la misión más importante para ti ahora.', style: TextStyle(color: LifeQuestColors.muted, fontSize: 10, height: 1.35)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      LifeQuestSurface(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('MISIÓN PRIORIZADA', style: TextStyle(color: LifeQuestColors.deepGreen, fontSize: 10, fontWeight: FontWeight.w800)),
            Icon(Icons.shield_outlined, color: LifeQuestColors.green, size: 19),
          ]),
          const SizedBox(height: 11),
          const Text('Preparar presentación del proyecto', style: TextStyle(color: LifeQuestColors.ink, fontSize: 20, height: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 13),
          _detail('Origen', 'Objetivo principal'),
          _detail('Urgencia', 'Alta'),
          _detail('Fecha límite', 'Hoy · 18:00'),
          const Divider(height: 20),
          _detail('Recompensa', '350 XP    ·    120 monedas'),
          const SizedBox(height: 9),
          SizedBox(width: double.infinity, height: 42, child: FilledButton.icon(
            onPressed: () => setState(() => _started = !_started),
            icon: Icon(_started ? Icons.check : Icons.play_arrow_rounded),
            label: Text(_started ? 'Misión iniciada' : 'Iniciar misión'),
            style: FilledButton.styleFrom(backgroundColor: LifeQuestColors.green),
          )),
        ]),
      ),
      const SizedBox(height: 14),
      const LifeQuestSurface(color: Color(0xFFEDFBF2), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('¿POR QUÉ ESTA MISIÓN ES IMPORTANTE?', style: TextStyle(color: LifeQuestColors.deepGreen, fontSize: 10, fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text('Tiene un alto impacto en tu objetivo actual y la fecha límite se acerca. Avanzar en ella desbloqueará otras tareas importantes.', style: TextStyle(color: LifeQuestColors.muted, fontSize: 10, height: 1.4, fontStyle: FontStyle.italic)),
      ])),
      const SizedBox(height: 16),
      LifeQuestSectionHeading('OTRAS MISIONES', action: '${_missions.length} activas'),
      const SizedBox(height: 7),
      for (final mission in _missions) ...[
        _mission(mission),
        const SizedBox(height: 7),
      ],
      SizedBox(height: 44, child: OutlinedButton.icon(
        onPressed: _createMission,
        icon: const Icon(Icons.add),
        label: const Text('Crear misión'),
      )),
    ],
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: LifeQuestColors.muted, fontSize: 11))),
      Text(value, style: const TextStyle(color: LifeQuestColors.deepGreen, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _mission(_Mission mission) => LifeQuestSurface(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: Row(children: [
      LifeQuestIconTile(mission.started ? Icons.play_circle_outline : Icons.flag_outlined),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(mission.title, style: const TextStyle(color: LifeQuestColors.ink, fontSize: 11, fontWeight: FontWeight.w700)),
        Text('${mission.due} · ${mission.duration}', style: const TextStyle(color: LifeQuestColors.muted, fontSize: 9)),
      ])),
      Text('${mission.xp} XP', style: const TextStyle(color: LifeQuestColors.deepGreen, fontSize: 9, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _CreateMissionSheet extends StatefulWidget {
  const _CreateMissionSheet();

  @override
  State<_CreateMissionSheet> createState() => _CreateMissionSheetState();
}

class _CreateMissionSheetState extends State<_CreateMissionSheet> {
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
    Navigator.pop(context, _Mission(
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
