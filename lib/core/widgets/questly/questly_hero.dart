import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Cabecera ilustrada (Hero.dc.html): paisaje de colinas, sol y árboles que
/// cambia con el tema. Con [onBack] muestra «volver» y el kicker baja.
class QuestlyHero extends StatelessWidget {
  const QuestlyHero({
    super.key,
    required this.kicker,
    required this.heading,
    this.icon = QIcons.sword,
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
                  child: SvgPicture.string(_landscape(t), fit: BoxFit.fill),
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

  static String _landscape(QHeroTone t) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 390 156" '
      'preserveAspectRatio="none">'
      '<circle cx="332" cy="40" r="16" fill="${_hex(t.sun)}" opacity=".85"/>'
      '<circle cx="296" cy="22" r="2" fill="${_hex(t.sun)}" opacity=".6"/>'
      '<circle cx="364" cy="66" r="1.6" fill="${_hex(t.sun)}" opacity=".5"/>'
      '<path d="M150 126 L196 96 L230 114 L268 92 L318 116 L354 98 L390 110 '
      'L390 156 L150 156Z" fill="${_hex(t.hill1)}"/>'
      '<path d="M0 140 Q100 122 200 138 T390 132 L390 156 L0 156Z" '
      'fill="${_hex(t.hill2)}"/>'
      '<path d="M300 150 L312 118 L324 150Z M326 152 L340 112 L354 152Z '
      'M356 150 L368 122 L380 150Z M206 152 L216 128 L226 152Z" '
      'fill="${_hex(t.trees)}"/></svg>';
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
