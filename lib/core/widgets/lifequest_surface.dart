import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

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
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.lq.line),
    ),
    child: child,
  );
}
