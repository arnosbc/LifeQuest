import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/widgets/lifequest_icon_tile.dart';
import 'package:proyecto_movil/core/widgets/lifequest_surface.dart';

/// Fila estándar de las listas de ejemplo: icono, título, detalle y extra.
class LifeQuestListRow extends StatelessWidget {
  const LifeQuestListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      child: Row(
        children: [
          LifeQuestIconTile(icon),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: LifeQuestColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: LifeQuestColors.deepGreen,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    ),
  );
}
