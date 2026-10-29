import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Cabecera (Hero.dc.html, DESIGN.md v2 §5): banda de color con formas
/// geométricas del tema. Con [onBack] muestra «volver» y el kicker baja.
class QuestlyHero extends StatelessWidget {
  const QuestlyHero({
    super.key,
    required this.kicker,
    required this.heading,
    this.icon = QIcons.focus,
    this.tone,
    this.onBack,
    this.backLabel = 'Volver',
    this.onAction,
    this.actionLabel,
    this.actionIcon = QIcons.plus,
    this.badge,
  }) : assert(onAction == null || actionLabel != null);

  final String kicker;
  final String heading;
  final QIcons icon;

  /// Null: el del tema y modo actuales.
  final QHeroTone? tone;
  final VoidCallback? onBack;
  final String backLabel;
  final VoidCallback? onAction;

  /// Nombre accesible del botón de acción (obligatorio con [onAction]).
  final String? actionLabel;
  final QIcons actionIcon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = tone ?? context.q.hero;
    final kickerRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QIcon(icon, color: t.kicker, size: 14, strokeWidth: 2.3),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            kicker.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: QText.meta(t.kicker),
          ),
        ),
      ],
    );
    return SizedBox(
      height: QSize.hero,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(QRadius.hero),
        ),
        child: ColoredBox(
          color: t.bg,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: SvgPicture.string(shapesSvg(t), fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: QSize.minTap,
                      ),
                      child: Row(
                        children: [
                          if (onBack != null)
                            Transform.translate(
                              offset: const Offset(-12, 0),
                              child: _HeroButton(
                                icon: QIcons.back,
                                label: backLabel,
                                onTap: onBack!,
                                round: true,
                              ),
                            )
                          else
                            Flexible(child: kickerRow),
                          const Spacer(),
                          if (onAction != null)
                            _HeroButton(
                              icon: actionIcon,
                              label: actionLabel!,
                              onTap: onAction!,
                              badge: badge,
                            ),
                        ],
                      ),
                    ),
                    if (onBack != null) kickerRow,
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Semantics(
                        header: true,
                        child: Text(
                          heading,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: QText.title1(
                            QHeroTone.text,
                          ).copyWith(letterSpacing: -0.3),
                        ),
                      ),
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

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  // Círculos concéntricos a la derecha y un arco abajo: quedan fuera del
  // ancho del título (20 + 260 px), así no bajan el contraste del texto.
  /// También la usa la cabecera de Acceso (auth_header.dart).
  static String shapesSvg(QHeroTone t) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 390 156" '
      'preserveAspectRatio="xMaxYMid slice">'
      '<circle cx="356" cy="134" r="96" fill="${_hex(t.shape1)}"/>'
      '<circle cx="356" cy="134" r="58" fill="${_hex(t.shape2)}"/>'
      '<circle cx="356" cy="134" r="24" fill="${_hex(t.shape3)}"/>'
      '<path d="M-10 156 Q120 128 250 156Z" fill="${_hex(t.shape3)}" '
      'opacity=".55"/>'
      '<circle cx="292" cy="30" r="5" fill="${_hex(t.dot)}" opacity=".85"/>'
      '<circle cx="270" cy="52" r="2.4" fill="${_hex(t.dot)}" opacity=".6"/>'
      '</svg>';
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.round = false,
    this.badge,
  });

  final QIcons icon;
  final String label;
  final VoidCallback onTap;
  final bool round;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(round ? QRadius.pill : QRadius.button);
    return Semantics(
      button: true,
      label: badge == null ? label : '$label, $badge',
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: round ? Colors.transparent : QHeroTone.actionBg,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox.square(
              dimension: QSize.minTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QIcon(
                    icon,
                    color: QHeroTone.text,
                    size: round ? 22 : 20,
                    strokeWidth: round ? 2.4 : 2.2,
                  ),
                  if (badge != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: QHeroTone.badgeBg,
                          borderRadius: BorderRadius.circular(QRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badge!,
                          style: QText.label(
                            QHeroTone.badgeText,
                          ).copyWith(fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
