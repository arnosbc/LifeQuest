import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

/// Vitrina del Perfil: los 3 logros más recientes como insignias y el
/// conteo; tocarla abre Logros.
class AchievementShowcase extends StatelessWidget {
  const AchievementShowcase({
    super.key,
    required this.profile,
    required this.onOpen,
  });

  final CharacterProfile profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final p = profile;
    return Semantics(
      button: true,
      label:
          'Logros: ${p.achievementsUnlocked} de ${p.achievementsTotal}. '
          '${p.recentAchievements.join(', ')}. Ver todos',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onOpen,
        behavior: HitTestBehavior.opaque,
        child: QuestlyCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tus logros',
                      style: QText.title3(q.text).copyWith(fontSize: 17),
                    ),
                  ),
                  Text(
                    '${p.achievementsUnlocked}/${p.achievementsTotal}',
                    style: QText.number(q.mustard, size: 15),
                  ),
                  Icon(Icons.chevron_right, color: q.text3),
                ],
              ),
              const SizedBox(height: QSpace.s),
              if (p.recentAchievements.isEmpty)
                Text(
                  'Completa tu primera tarea para ganar tu primer logro.',
                  style: QText.body(q.text2).copyWith(fontSize: 13),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, name) in p.recentAchievements.indexed) ...[
                      if (i > 0) const SizedBox(width: QSpace.s),
                      Expanded(child: _Badge(name: name)),
                    ],
                    // Con menos de 3, las insignias conservan su ancho.
                    for (var i = p.recentAchievements.length; i < 3; i++) ...[
                      const SizedBox(width: QSpace.s),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: q.mustardTint,
            shape: BoxShape.circle,
            border: Border.all(color: q.mustard, width: 2),
          ),
          alignment: Alignment.center,
          child: QIcon(QIcons.trophy, color: q.mustardInk, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: QText.label(q.text).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
