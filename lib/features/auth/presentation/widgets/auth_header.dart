import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_hero.dart';

/// Cabecera de Acceso (Auth.dc.html con DESIGN.md v2): banda del tema con las
/// formas del Hero, la marca y su lema. Llega hasta arriba, bajo la barra de
/// estado.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.height = 210});

  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.q.hero;
    return SizedBox(
      height: height + MediaQuery.paddingOf(context).top,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: ColoredBox(
          color: t.bg,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: SvgPicture.string(
                    QuestlyHero.shapesSvg(t),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: QSpace.xl,
                right: QSpace.xl,
                bottom: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'LifeQuest',
                        style: QText.display(QHeroTone.text),
                      ),
                    ),
                    const SizedBox(height: QSpace.xs),
                    Text(
                      'Avanza paso a paso y ve tu progreso',
                      style: QText.body(t.kicker).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
