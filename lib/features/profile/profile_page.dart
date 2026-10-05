import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

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
      LifeQuestSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 31,
              backgroundColor: LifeQuestColors.green,
              child: Text(
                userName.isEmpty ? 'A' : userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            _tag('Nivel 24 · Estratega'),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'XP',
                  style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
                ),
                Text(
                  '7,850 / 12,000',
                  style: TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const LinearProgressIndicator(
              value: .65,
              minHeight: 5,
              color: LifeQuestColors.green,
              backgroundColor: Color(0xFFE3EEE7),
            ),
          ],
        ),
      ),
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
      LifeQuestSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasa de finalización 76%',
                  style: TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '38/50',
                  style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const LinearProgressIndicator(
              value: .76,
              minHeight: 5,
              color: LifeQuestColors.green,
              backgroundColor: Color(0xFFE3EEE7),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: _quick(context, Icons.visibility_outlined, 'Vision Board'),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _quick(
              context,
              Icons.inventory_2_outlined,
              'Inventario / Logros',
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(child: _quick(context, Icons.history, 'Historial')),
          const SizedBox(width: 7),
          Expanded(child: _quick(context, Icons.auto_awesome, 'Game Master')),
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
          _Skill('Inglés', 'Nivel 18'),
          _Skill('Salud', 'Nivel 20'),
          _Skill('Diseño UX', 'Nivel 17'),
          _Skill('Universidad', 'Nivel 16'),
        ],
      ),
      const SizedBox(height: 13),
      const LifeQuestSectionHeading('CUENTA'),
      const SizedBox(height: 6),
      _accountAction(
        context,
        Icons.notifications_outlined,
        'Notificaciones',
        'Preferencias de notificaciones.',
        onTap: onOpenNotifications,
      ),
      _accountAction(
        context,
        Icons.palette_outlined,
        'Apariencia',
        'Tu tema actual es claro.',
        onTap: onOpenAppearance,
      ),
      _accountAction(
        context,
        Icons.help_outline,
        'Ayuda',
        'Centro de ayuda.',
        onTap: onOpenHelp,
      ),
    ],
  );

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: LifeQuestColors.softGreen,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: LifeQuestColors.deepGreen,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _quick(BuildContext context, IconData icon, String label) => InkWell(
    onTap: () => showLifeQuestMessage(context, label),
    borderRadius: BorderRadius.circular(9),
    child: LifeQuestSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: LifeQuestColors.deepGreen, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _accountAction(
    BuildContext context,
    IconData icon,
    String title,
    String message, {
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: InkWell(
      onTap: onTap ?? () => showLifeQuestMessage(context, message),
      borderRadius: BorderRadius.circular(9),
      child: LifeQuestSurface(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: LifeQuestColors.deepGreen, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: LifeQuestColors.muted,
              size: 17,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Skill extends StatelessWidget {
  const _Skill(this.name, this.level);

  final String name;
  final String level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LifeQuestColors.line),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '◈ $name',
          style: const TextStyle(
            color: LifeQuestColors.deepGreen,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          level,
          style: const TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
      ],
    ),
  );
}
