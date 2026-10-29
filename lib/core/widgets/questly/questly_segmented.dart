import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Pestañas segmentadas: fondo de pista y la activa en tarjeta con sombra suave.
class QuestlySegmented<T> extends StatelessWidget {
  const QuestlySegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  /// Valor y texto de cada pestaña.
  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      padding: const EdgeInsets.all(QSpace.xs),
      decoration: BoxDecoration(
        color: q.track,
        borderRadius: BorderRadius.circular(QRadius.button),
      ),
      child: Row(
        children: [
          for (final (i, (value, label)) in segments.indexed) ...[
            if (i > 0) const SizedBox(width: QSpace.xs),
            Expanded(
              child: _Segment(
                label: label,
                active: value == selected,
                onTap: () => onChanged(value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final radius = BorderRadius.circular(11);
    return Semantics(
      button: true,
      selected: active,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: context.motion(QMotion.press),
        decoration: BoxDecoration(
          color: active ? q.card : Colors.transparent,
          borderRadius: radius,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: q.segmentShadow,
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: QSize.minTap),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: QText.label(active ? q.text : q.text2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
