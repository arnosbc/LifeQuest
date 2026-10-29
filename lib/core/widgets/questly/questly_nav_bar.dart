import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Barra inferior de 5 pestañas (Main.dc.html): la activa lleva una píldora
/// de tinte y el texto en tinta.
class QuestlyNavBar extends StatelessWidget {
  const QuestlyNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (QIcons.home, 'Inicio'),
    (QIcons.stage, 'Planificador'),
    (QIcons.habits, 'Hábitos'),
    (QIcons.focus, 'Foco'),
    (QIcons.profile, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Principal',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: q.card,
          border: Border(top: BorderSide(color: q.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Row(
              children: [
                for (final (i, (icon, label)) in _items.indexed)
                  Expanded(
                    child: _NavItem(
                      icon: icon,
                      label: label,
                      active: i == currentIndex,
                      onTap: () => onSelected(i),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final QIcons icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final color = active ? q.ink : q.text2;
    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(QRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: context.motion(QMotion.press),
                width: QSize.minTap,
                height: 28,
                decoration: BoxDecoration(
                  color: active ? q.tint : Colors.transparent,
                  borderRadius: BorderRadius.circular(QRadius.pill),
                ),
                alignment: Alignment.center,
                child: QIcon(icon, color: color),
              ),
              const SizedBox(height: 3),
              // «Planificador» no cabe a 12 px en 360 de ancho: se encoge un
              // poco en vez de cortarse.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: QText.label(color).copyWith(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
