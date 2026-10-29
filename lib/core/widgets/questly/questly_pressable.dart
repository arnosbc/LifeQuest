import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Superficie «de juego»: al pulsarla baja 3 px y pierde la sombra sólida
/// (DESIGN.md §1). Con foco de teclado muestra el anillo de foco.
class QuestlyPressable extends StatefulWidget {
  const QuestlyPressable({
    super.key,
    required this.decoration,
    required this.child,
    required this.radius,
    this.onTap,
    this.padding,
    this.constraints,
    this.semanticsLabel,
    this.selected,
  });

  final BoxDecoration decoration;
  final Widget child;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final String? semanticsLabel;
  final bool? selected;

  @override
  State<QuestlyPressable> createState() => _QuestlyPressableState();
}

class _QuestlyPressableState extends State<QuestlyPressable> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    final pressed = _pressed && widget.onTap != null;
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticsLabel,
      child: AnimatedContainer(
        duration: context.motion(QMotion.press),
        transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
        constraints: widget.constraints,
        decoration: pressed
            ? widget.decoration.copyWith(boxShadow: const [])
            : widget.decoration,
        foregroundDecoration: _focused
            ? BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: context.q.focus, width: 3),
              )
            : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: borderRadius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onFocusChange: (v) => setState(() => _focused = v),
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
