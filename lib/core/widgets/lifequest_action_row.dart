import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/widgets/lifequest_surface.dart';

/// Fila con icono, título, detalle y un botón de acción (comprar, atacar,
/// pedir misión…). Sin [onAction] el botón queda deshabilitado.
class LifeQuestActionRow extends StatelessWidget {
  const LifeQuestActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onAction,
    this.busy = false,
    this.menu,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool busy;

  /// Menú «⋯» opcional tras el botón.
  final Widget? menu;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.lq.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: context.lq.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : onAction,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(actionLabel),
          ),
          ?menu,
        ],
      ),
    ),
  );
}
