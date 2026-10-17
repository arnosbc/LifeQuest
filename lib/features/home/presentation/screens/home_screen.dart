import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/goals/presentation/screens/goals_screen.dart';
import 'package:proyecto_movil/features/journal/presentation/screens/journal_screen.dart';
import 'package:proyecto_movil/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:proyecto_movil/features/rpgenie/presentation/screens/rpgenie_screen.dart';
import 'package:proyecto_movil/features/stage/presentation/screens/stage_screen.dart';
import 'package:proyecto_movil/features/tavern/presentation/screens/tavern_screen.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/dashboard_greeting.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/habit_strip.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/level_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/priority_mission_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/quick_action.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.onNavigate,
  });

  final String userName;
  final ValueChanged<int> onNavigate;

  static const _sections = [
    (Icons.auto_awesome_outlined, 'RPGenie', RpgenieScreen()),
    (Icons.dashboard_outlined, 'Stage · P.A.R.A.', StageScreen()),
    (Icons.auto_stories_outlined, 'Diario', JournalScreen()),
    (Icons.flag_outlined, 'Objetivos', GoalsScreen()),
    (Icons.sports_bar_outlined, 'Taverna', TavernScreen()),
    (Icons.storefront_outlined, 'Marketplace', MarketplaceScreen()),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(19, 12, 19, 20),
    children: [
      DashboardGreeting(userName: userName, onOpenProfile: () => onNavigate(4)),
      const SizedBox(height: 12),
      const LevelCard(),
      const SizedBox(height: 14),
      LifeQuestSectionHeading(
        'MISIÓN PRIORITARIA',
        action: 'Ver todas',
        onTap: () => onNavigate(1),
      ),
      const SizedBox(height: 7),
      PriorityMissionCard(onContinue: () => onNavigate(1)),
      const SizedBox(height: 13),
      LifeQuestSectionHeading(
        'HÁBITOS DE HOY',
        action: '🔥 12 días',
        onTap: () => onNavigate(3),
      ),
      const SizedBox(height: 7),
      const HabitStrip(),
      const SizedBox(height: 14),
      const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
      const SizedBox(height: 7),
      _pair(
        QuickAction(
          icon: Icons.add_box_outlined,
          label: 'Nueva tarea',
          onTap: () => onNavigate(1),
        ),
        QuickAction(
          icon: Icons.timer_outlined,
          label: 'Modo focus',
          onTap: () => onNavigate(2),
        ),
      ),
      const SizedBox(height: 7),
      _pair(
        QuickAction(
          icon: Icons.monitor_heart_outlined,
          label: 'Registrar hábito',
          onTap: () => onNavigate(3),
        ),
        QuickAction(
          icon: Icons.auto_awesome,
          label: 'Game Master',
          onTap: () => onNavigate(2),
        ),
      ),
      const SizedBox(height: 14),
      // RF-114: secciones que no caben en la barra inferior.
      const LifeQuestSectionHeading('EXPLORA EL REINO'),
      for (var i = 0; i < _sections.length; i += 2) ...[
        const SizedBox(height: 7),
        _pair(
          _sectionAction(context, _sections[i]),
          _sectionAction(context, _sections[i + 1]),
        ),
      ],
    ],
  );

  Widget _pair(Widget left, Widget right) => Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: 8),
      Expanded(child: right),
    ],
  );

  Widget _sectionAction(
    BuildContext context,
    (IconData, String, Widget) section,
  ) {
    final (icon, label, page) = section;
    return QuickAction(
      icon: icon,
      label: label,
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LifeQuestTheme.lightOnly(
            Scaffold(
              backgroundColor: LifeQuestColors.background,
              appBar: AppBar(backgroundColor: LifeQuestColors.background),
              body: SafeArea(child: page),
            ),
          ),
        ),
      ),
    );
  }
}
