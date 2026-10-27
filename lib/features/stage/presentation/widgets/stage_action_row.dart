import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Acción del menú de una fila; [onSelected] null la muestra deshabilitada.
typedef StageRowAction = ({String label, VoidCallback? onSelected});

/// Fila de Stage con menú de acciones (completar, archivar, copiar…).
class StageActionRow extends StatelessWidget {
  const StageActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.trailing,
    this.progress,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  /// 0–1; null sin barra de progreso.
  final double? progress;
  final List<StageRowAction> actions;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
      child: Row(
        children: [
          LifeQuestIconTile(icon),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.lq.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.lq.muted, fontSize: 10),
                ),
                if (progress case final value?) ...[
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    color: context.lq.deepGreen,
                    backgroundColor: context.lq.line,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                trailing!,
                style: TextStyle(
                  color: context.lq.deepGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          PopupMenuButton<int>(
            enabled: enabled,
            tooltip: 'Opciones de «$title»',
            icon: Icon(Icons.more_vert, color: context.lq.muted),
            onSelected: (i) => actions[i].onSelected?.call(),
            itemBuilder: (_) => [
              for (var i = 0; i < actions.length; i++)
                PopupMenuItem(
                  value: i,
                  enabled: actions[i].onSelected != null,
                  child: Text(actions[i].label),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
