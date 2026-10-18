import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

/// Skill del árbol de habilidades. Tocarla abre sus opciones.
class SkillTile extends StatelessWidget {
  const SkillTile({super.key, required this.skill, required this.onTap});

  final Skill skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: LifeQuestColors.line),
      borderRadius: BorderRadius.circular(11),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Nivel ${skill.level}',
              style: const TextStyle(
                color: LifeQuestColors.deepGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: skill.progress,
              minHeight: 6,
              color: LifeQuestColors.green,
              backgroundColor: LifeQuestColors.softGreen,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              semanticsLabel: 'XP de ${skill.name}',
              semanticsValue: '${(skill.progress * 100).round()} %',
            ),
          ],
        ),
      ),
    ),
  );
}

/// Casilla para crear una skill nueva.
class AddSkillTile extends StatelessWidget {
  const AddSkillTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: LifeQuestColors.softGreen,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: LifeQuestColors.line),
      borderRadius: BorderRadius.circular(11),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: LifeQuestColors.deepGreen),
            SizedBox(height: 4),
            Text(
              'Añadir skill',
              style: TextStyle(
                color: LifeQuestColors.deepGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
