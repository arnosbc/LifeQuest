import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';
import 'widgets/account_action_tile.dart';
import 'widgets/character_card.dart';
import 'widgets/completion_rate_card.dart';
import 'widgets/profile_quick_link.dart';
import 'widgets/skill_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.userName,
    required this.onOpenNotifications,
    required this.onOpenHelp,
    required this.onOpenAppearance,
    required this.onOpenSettings,
  });

  final String userName;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Perfil',
    subtitle: 'Tu progreso, a tu manera.',
    trailing: IconButton(
      onPressed: onOpenSettings,
      tooltip: 'Configuración',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.settings_outlined, size: 18),
    ),
    children: [
      CharacterCard(userName: userName),
      const SizedBox(height: 11),
      const Row(
        children: [
          Expanded(
            child: LifeQuestStat(value: '100 / 100', label: '♡ Puntos de vida'),
          ),
          SizedBox(width: 7),
          Expanded(
            child: LifeQuestStat(value: '2,450', label: '◉ Monedas'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const CompletionRateCard(),
      const SizedBox(height: 14),
      const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
      const SizedBox(height: 6),
      const Row(
        children: [
          Expanded(
            child: ProfileQuickLink(
              icon: Icons.visibility_outlined,
              label: 'Vision Board',
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: ProfileQuickLink(
              icon: Icons.inventory_2_outlined,
              label: 'Inventario / Logros',
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Row(
        children: [
          Expanded(
            child: ProfileQuickLink(icon: Icons.history, label: 'Historial'),
          ),
          SizedBox(width: 7),
          Expanded(
            child: ProfileQuickLink(
              icon: Icons.auto_awesome,
              label: 'Game Master',
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const LifeQuestSectionHeading('ÁRBOL DE HABILIDADES'),
      const SizedBox(height: 6),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 2.7,
        children: const [
          SkillTile('Inglés', 'Nivel 18'),
          SkillTile('Salud', 'Nivel 20'),
          SkillTile('Diseño UX', 'Nivel 17'),
          SkillTile('Universidad', 'Nivel 16'),
        ],
      ),
      const SizedBox(height: 13),
      const LifeQuestSectionHeading('CUENTA'),
      const SizedBox(height: 6),
      AccountActionTile(
        icon: Icons.notifications_outlined,
        title: 'Notificaciones',
        onTap: onOpenNotifications,
      ),
      AccountActionTile(
        icon: Icons.palette_outlined,
        title: 'Apariencia',
        onTap: onOpenAppearance,
      ),
      AccountActionTile(
        icon: Icons.help_outline,
        title: 'Ayuda',
        onTap: onOpenHelp,
      ),
    ],
  );
}
