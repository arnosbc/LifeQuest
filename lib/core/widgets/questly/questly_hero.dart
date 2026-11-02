import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Cabecera clara del diseño LifeQuest. Con [onBack]: flecha a la izquierda y
/// título centrado («Detalle de meta»). Sin él: título grande a la izquierda
/// con [kicker] debajo como bajada («Hola, Estevan»).
class QuestlyHero extends StatelessWidget {
  const QuestlyHero({
    super.key,
    required this.kicker,
    required this.heading,
    this.icon = QIcons.focus,
    this.onBack,
    this.backLabel = 'Volver',
    this.onAction,
    this.actionLabel,
    this.actionIcon = QIcons.plus,
    this.badge,
  }) : assert(onAction == null || actionLabel != null);

  final String kicker;
  final String heading;

  /// Se conserva por compatibilidad; la cabecera clara no lo dibuja.
  final QIcons icon;
  final VoidCallback? onBack;
  final String backLabel;
  final VoidCallback? onAction;

  /// Nombre accesible del botón de acción (obligatorio con [onAction]).
  final String? actionLabel;
  final QIcons actionIcon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final action = onAction == null
        ? const SizedBox(width: QSize.minTap)
        : _HeroButton(
            icon: actionIcon,
            label: actionLabel!,
            onTap: onAction!,
            badge: badge,
          );
    if (onBack != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: [
            _HeroButton(icon: QIcons.back, label: backLabel, onTap: onBack!),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: QText.title3(q.text).copyWith(fontSize: 17),
                ),
              ),
            ),
            action,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      heading,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: QText.title2(q.text).copyWith(fontSize: 24),
                    ),
                  ),
                  if (kicker.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      kicker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: QText.body(q.text2).copyWith(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
          action,
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final QIcons icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      label: badge == null ? label : '$label, $badge',
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: QSize.minTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                QIcon(icon, color: q.text, size: 22, strokeWidth: 2),
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
                        color: q.accent,
                        borderRadius: BorderRadius.circular(QRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge!,
                        style: QText.label(
                          q.onAccent,
                        ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
