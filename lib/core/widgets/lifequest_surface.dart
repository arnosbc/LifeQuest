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
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: context.lq.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 7,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}
