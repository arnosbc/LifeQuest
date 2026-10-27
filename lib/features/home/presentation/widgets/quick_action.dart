import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Atajo del Home. Horizontal (icono a la izquierda) para acciones rápidas;
/// vertical (icono arriba) para las secciones del reino.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.vertical = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: vertical ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: context.lq.ink,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );

    return Material(
      color: context.lq.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.lq.line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: vertical
                ? const EdgeInsets.fromLTRB(6, 14, 6, 12)
                : const EdgeInsets.all(10),
            child: vertical
                ? Column(
                    children: [
                      LifeQuestIconTile(icon),
                      const SizedBox(height: 8),
                      text,
                    ],
                  )
                : Row(
                    children: [
                      LifeQuestIconTile(icon),
                      const SizedBox(width: 10),
                      Expanded(child: text),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
