import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.name,
    required this.profile,
    required this.onEditIdentity,
  });

  final String name;
  final CharacterProfile profile;
  final VoidCallback onEditIdentity;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return LifeQuestSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: LifeQuestColors.deepGreen,
                child: Text(
                  name.isEmpty ? 'A' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LifeQuestColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.characterClass == null
                          ? 'Nivel ${p.level}'
                          : 'Nivel ${p.level} · ${p.characterClass}',
                      style: const TextStyle(
                        color: LifeQuestColors.deepGreen,
                        fontSize: 13,
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
                color: LifeQuestColors.deepGreen,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: p.identityStatement == null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onEditIdentity,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('¿Quién eres en este reino?'),
                      style: TextButton.styleFrom(
                        foregroundColor: LifeQuestColors.deepGreen,
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: Text(
                      p.identityStatement!,
                      style: const TextStyle(
                        color: LifeQuestColors.ink,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'XP',
                        style: TextStyle(
                          color: LifeQuestColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_number(p.currentXp)} / ${_number(p.xpToNextLevel)}',
                      style: const TextStyle(
                        color: LifeQuestColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Semantics(
                  label: 'Progreso de XP',
                  value: '${(p.xpProgress * 100).round()} %',
                  child: LinearProgressIndicator(
                    value: p.xpProgress,
                    minHeight: 8,
                    color: LifeQuestColors.green,
                    backgroundColor: LifeQuestColors.softGreen,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 12450 → "12.450".
String _number(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);
