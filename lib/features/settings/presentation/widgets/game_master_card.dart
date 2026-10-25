import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/setting_link.dart';

class GameMasterCard extends StatefulWidget {
  const GameMasterCard({
    super.key,
    required this.onOpenNotificationPreferences,
    required this.onOpenAppearance,
  });

  final VoidCallback onOpenNotificationPreferences;
  final VoidCallback onOpenAppearance;

  @override
  State<GameMasterCard> createState() => _GameMasterCardState();
}

class _GameMasterCardState extends State<GameMasterCard> {
  String _difficulty = 'Normal';

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil / Game Master',
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Dificultad',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _difficultyOption('Fácil'),
            const SizedBox(width: 5),
            _difficultyOption('Normal'),
            const SizedBox(width: 5),
            _difficultyOption('Difícil'),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'Tienda',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 4),
        SettingLink(
          icon: Icons.shopping_bag_outlined,
          title: 'Contenido de la Tienda',
          description: 'Accede a paquetes, recompensas y personalizaciones.',
          onTap: () => showLifeQuestMessage(
            context,
            'La tienda estará disponible próximamente.',
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Notificaciones',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 4),
        SettingLink(
          icon: Icons.notifications_active_outlined,
          title: 'Preferencias de notificaciones',
          description: 'Ajusta recordatorios, logros y alertas del juego.',
          onTap: widget.onOpenNotificationPreferences,
        ),
        const SizedBox(height: 7),
        const Text(
          'Apariencia',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 4),
        SettingLink(
          icon: Icons.palette_outlined,
          title: 'Apariencia',
          description: 'Modo claro, oscuro o del sistema.',
          onTap: widget.onOpenAppearance,
        ),
      ],
    ),
  );

  Widget _difficultyOption(String label) {
    final selected = _difficulty == label;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _difficulty = label),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? LifeQuestColors.softGreen : Colors.white,
              border: Border.all(
                color: selected ? LifeQuestColors.green : LifeQuestColors.line,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 8,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
