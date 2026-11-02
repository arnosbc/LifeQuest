import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Barra inferior de 5 pestañas: blanca con sombra suave; la activa va en
/// lavanda con el texto en negrita.
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(QRadius.sheet),
          ),
          boxShadow: qSolidShadow(q.cardShadow, y: -8),
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
    final color = active ? q.accent : q.text2;
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
              SizedBox(
                height: 28,
                child: Center(
                  child: QIcon(
                    icon,
                    color: color,
                    strokeWidth: active ? 2.4 : 1.8,
                  ),
                ),
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
