import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/level_rank.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/profile_format.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/profile_look_widgets.dart';

/// Cabecera morada del Perfil: avatar, nombre, identidad y avance de nivel.
/// Llega hasta arriba; [bottomInset] deja sitio a la tarjeta que la monta.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.name,
    required this.profile,
    required this.onEditIdentity,
    required this.onChooseTitle,
    required this.onCustomize,
    this.look = const ProfileLook(),
    this.bottomInset = 40,
  });

  final String name;
  final CharacterProfile profile;
  final VoidCallback onEditIdentity;
  final VoidCallback onChooseTitle;

  /// Abre «Personalizar perfil» (foto, emoji, personaje, luz y fondo).
  final VoidCallback onCustomize;
  final ProfileLook look;
  final double bottomInset;

  static const _soft = Color(0xFFEDE6FB);

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final xpLeft = (p.xpToNextLevel - p.currentXp).clamp(0, p.xpToNextLevel);
    final linkStyle = TextButton.styleFrom(
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 48),
      textStyle: QText.label(Colors.white),
    );
    return Stack(
      children: [
        Positioned.fill(child: ProfileBackdropView(look: look)),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
          child: Column(
            children: [
              SizedBox.square(
                dimension: 104,
                child: Stack(
                  children: [
                    ProfileAvatar(look: look),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Personalizar perfil',
                          onPressed: onCustomize,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          color: const Color(0xFF5B3FA8),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(36, 36),
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: QSpace.m),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: QText.title2(Colors.white).copyWith(fontSize: 20),
              ),
              if (p.activeTitle case final title?) ...[
                const SizedBox(height: 2),
                Text(
                  title.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QText.body(_soft).copyWith(fontSize: 13),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '${levelRank(p.level)} · Nivel ${p.level}',
                style: QText.label(Colors.white),
              ),
              const SizedBox(height: QSpace.s),
              if (p.identityStatement == null)
                TextButton.icon(
                  onPressed: onEditIdentity,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('¿En quién te quieres convertir?'),
                  style: linkStyle,
                )
              else
                Text(
                  p.identityStatement!,
                  textAlign: TextAlign.center,
                  style: QText.body(Colors.white).copyWith(fontSize: 14),
                ),
              TextButton.icon(
                onPressed: onChooseTitle,
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: const Text('Elegir insignia'),
                style: linkStyle,
              ),
              const SizedBox(height: QSpace.xs),
              Row(
                children: [
                  Text('XP', style: QText.label(_soft).copyWith(fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${formatNumber(p.currentXp)} / '
                      '${formatNumber(p.xpToNextLevel)}',
                      textAlign: TextAlign.end,
                      style: QText.number(Colors.white, size: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QSpace.s),
              LinearProgressIndicator(
                value: p.xpProgress,
                minHeight: 8,
                color: Colors.white,
                backgroundColor: const Color(0x40FFFFFF),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                semanticsLabel: 'Progreso de XP',
                semanticsValue: '${(p.xpProgress * 100).round()} %',
              ),
              if (p.xpToNextLevel > 0) ...[
                const SizedBox(height: QSpace.s),
                Text(
                  'Te faltan ${formatNumber(xpLeft)} XP para el '
                  'nivel ${p.level + 1}',
                  style: QText.body(_soft).copyWith(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
