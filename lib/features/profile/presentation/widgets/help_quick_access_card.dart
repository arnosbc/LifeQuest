import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class HelpQuickAccessCard extends StatelessWidget {
  const HelpQuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: LifeQuestSurface(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LifeQuestIconTile(icon, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: context.lq.muted, fontSize: 8, height: 1.3),
          ),
        ],
      ),
    ),
  );
}
