import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

/// Diario: texto del Diario del Héroe + Historial filtrable (RF-116).
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  static const _filters = ['Todo', 'Cumplidas', 'Falladas'];
  static const _log = [
    ('Leer 20 páginas', 'Hábito · hoy', '+10 XP', true),
    ('Mazmorra de 25 min', 'Deep Working · hoy', '+25 XP', true),
    ('Entregar borrador', 'Tarea · ayer', '−5 HP', false),
    ('Preparar reunión', 'Tarea · ayer', '+30 XP', true),
  ];

  String _filter = _filters.first;

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Diario',
    subtitle: 'La crónica de tu aventura.',
    children: [
      const LifeQuestSurface(
        color: LifeQuestColors.softGreen,
        child: Text(
          'Hoy cruzaste dos mazmorras y mantuviste viva tu racha de lectura. '
          'Mañana te espera la presentación: el reino confía en ti.',
          style: TextStyle(color: LifeQuestColors.ink, fontSize: 12),
        ),
      ),
      const SizedBox(height: 14),
      const LifeQuestSectionHeading('HISTORIAL DE MISIONES'),
      const SizedBox(height: 7),
      Wrap(
        spacing: 6,
        children: [
          for (final f in _filters)
            ChoiceChip(
              label: Text(f),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            ),
        ],
      ),
      const SizedBox(height: 7),
      for (final (title, detail, change, done) in _log)
        if (_filter == 'Todo' || (_filter == 'Cumplidas') == done)
          LifeQuestListRow(
            icon: done ? Icons.check_circle_outline : Icons.cancel_outlined,
            title: title,
            subtitle: detail,
            trailing: change,
          ),
    ],
  );
}
