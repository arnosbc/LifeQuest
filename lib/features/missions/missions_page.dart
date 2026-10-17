import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';
import 'models/mission.dart';
import 'widgets/create_mission_sheet.dart';
import 'widgets/mission_importance_card.dart';
import 'widgets/mission_tile.dart';
import 'widgets/prioritized_mission_card.dart';
import 'widgets/rp_genie_tip_card.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  final List<Mission> _missions = [
    const Mission(
      title: 'Leer 20 páginas', description: 'Avanzar en el libro actual',
      due: 'Hoy', duration: '30 min', priority: 'Media', xp: 120, coins: 40,
    ),
    const Mission(
      title: 'Salir a caminar', description: 'Dar un paseo al aire libre',
      due: 'Hoy', duration: '30 min', priority: 'Media', xp: 180, coins: 60,
    ),
    const Mission(
      title: 'Planificar la semana', description: 'Organizar prioridades y agenda',
      due: 'Mañana', duration: '1 h', priority: 'Baja', xp: 200, coins: 70,
    ),
  ];
  bool _started = false;

  Future<void> _createMission() async {
    final result = await showModalBottomSheet<Mission>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateMissionSheet(),
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
      const RpGenieTipCard(),
      const SizedBox(height: 16),
      PrioritizedMissionCard(
        started: _started,
        onToggleStart: () => setState(() => _started = !_started),
      ),
      const SizedBox(height: 14),
      const MissionImportanceCard(),
      const SizedBox(height: 16),
      LifeQuestSectionHeading('OTRAS MISIONES', action: '${_missions.length} activas'),
      const SizedBox(height: 7),
      for (final mission in _missions) ...[
        MissionTile(mission: mission),
        const SizedBox(height: 7),
      ],
      SizedBox(height: 44, child: OutlinedButton.icon(
        onPressed: _createMission,
        icon: const Icon(Icons.add),
        label: const Text('Crear misión'),
      )),
    ],
  );
}
