import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';

class LifeQuestSurface extends StatelessWidget {
  const LifeQuestSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Por defecto, la superficie del tema.
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? context.lq.surface,
      borderRadius: BorderRadius.circular(QRadius.block),
      border: Border.all(color: context.lq.line),
      boxShadow: qSolidShadow(context.q.cardShadow),
    ),
    child: child,
  );
}
