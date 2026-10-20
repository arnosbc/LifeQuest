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
    color: context.lq.surface,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: context.lq.line),
      borderRadius: BorderRadius.circular(11),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Nivel ${skill.level}',
              style: TextStyle(
                color: context.lq.deepGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: skill.progress,
              minHeight: 6,
              color: context.lq.green,
              backgroundColor: context.lq.softGreen,
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
    color: context.lq.softGreen,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: context.lq.line),
      borderRadius: BorderRadius.circular(11),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: context.lq.deepGreen),
            const SizedBox(height: 4),
            Text(
              'Añadir skill',
              style: TextStyle(
                color: context.lq.deepGreen,
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
