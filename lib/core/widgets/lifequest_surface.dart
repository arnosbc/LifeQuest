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

  /// Con color es un bloque relleno; sin color es una sección de la hoja,
  /// separada solo por un filete (nada de tarjetas dentro de la hoja).
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: color != null
        ? BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))
        : BoxDecoration(
            border: Border(bottom: BorderSide(color: context.lq.line)),
          ),
    child: child,
  );
}
