import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_pressable.dart';

/// Tarjeta: borde de 1 px y sombra sólida de 4 px. Con [onTap] se pulsa
/// bajando 3 px.
class QuestlyCard extends StatelessWidget {
  const QuestlyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(QSpace.l),
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final decoration = BoxDecoration(
      color: q.card,
      borderRadius: BorderRadius.circular(QRadius.card),
      border: Border.all(color: q.border),
      boxShadow: qSolidShadow(q.cardShadow),
    );
    if (onTap == null) {
      return Container(decoration: decoration, padding: padding, child: child);
    }
    return QuestlyPressable(
      decoration: decoration,
      radius: QRadius.card,
      padding: padding,
      onTap: onTap,
      semanticsLabel: semanticsLabel,
      child: child,
    );
  }
}
