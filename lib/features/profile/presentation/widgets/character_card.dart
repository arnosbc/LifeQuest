import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/profile_format.dart';

/// Identidad del héroe y su avance hacia el siguiente nivel.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.name,
    required this.profile,
    required this.onEditIdentity,
    required this.onChooseTitle,
  });

  final String name;
  final CharacterProfile profile;
  final VoidCallback onEditIdentity;
  final VoidCallback onChooseTitle;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final p = profile;
    final xpLeft = (p.xpToNextLevel - p.currentXp).clamp(0, p.xpToNextLevel);
    return LifeQuestSurface(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: lq.deepGreen,
                  child: Text(
                    name.isEmpty ? 'A' : name.characters.first.toUpperCase(),
                    style: TextStyle(
                      color: lq.onDeepGreen,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: lq.ink,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (p.activeTitle case final title?) ...[
                      const SizedBox(height: 2),
                      Text(
                        title.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: lq.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      p.characterClass == null
                          ? 'Nivel ${p.level}'
                          : 'Nivel ${p.level} · ${p.characterClass}',
                      style: TextStyle(
                        color: lq.deepGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar identidad',
                onPressed: onEditIdentity,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: lq.deepGreen,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onChooseTitle,
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Elegir título'),
            style: TextButton.styleFrom(
              foregroundColor: lq.deepGreen,
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: p.identityStatement == null
                ? TextButton.icon(
                    onPressed: onEditIdentity,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('¿Quién eres en este reino?'),
                    style: TextButton.styleFrom(
                      foregroundColor: lq.deepGreen,
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    p.identityStatement!,
                    style: TextStyle(color: lq.ink, fontSize: 15, height: 1.45),
                  ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'XP',
                      style: TextStyle(
                        color: lq.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${formatNumber(p.currentXp)} / '
                        '${formatNumber(p.xpToNextLevel)}',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: lq.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: p.xpProgress,
                  minHeight: 10,
                  color: lq.green,
                  backgroundColor: lq.softGreen,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  semanticsLabel: 'Progreso de XP',
                  semanticsValue: '${(p.xpProgress * 100).round()} %',
                ),
                if (p.xpToNextLevel > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Te faltan ${formatNumber(xpLeft)} XP para el '
                    'nivel ${p.level + 1}',
                    style: TextStyle(color: lq.muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
