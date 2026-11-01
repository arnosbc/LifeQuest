import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Fila de la hoja: check, hora (o icono) y título; debajo, una línea gris y
/// una acción. La fila [current] es la única marcada en rojo, como el día
/// señalado en un calendario.
class SheetRow extends StatelessWidget {
  const SheetRow({
    super.key,
    required this.leading,
    required this.title,
    this.time = '',
    this.timeIcon,
    this.subtitle,
    this.action,
    this.trailing,
    this.current = false,
    this.done = false,
    this.muted = false,
  });

  final Widget leading;
  final String title;
  final String time;
  final IconData? timeIcon;
  final String? subtitle;
  final Widget? action;
  final Widget? trailing;
  final bool current;
  final bool done;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final ink = done || muted ? q.text2 : q.text;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: q.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Transform.translate(offset: const Offset(-8, 0), child: leading),
              if (time.isNotEmpty || timeIcon != null)
                SizedBox(
                  width: 48,
                  child: timeIcon != null
                      ? Icon(timeIcon, size: 18, color: q.text2)
                      : Text(
                          time,
                          style: QText.number(
                            current ? q.mark : q.text2,
                            size: 13,
                          ),
                        ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: context.motion(QMotion.fade),
                      curve: QMotion.easeOut,
                      style: QText.body(ink).copyWith(
                        fontSize: 16,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: q.text2,
                      ),
                      child: Text(title),
                    ),
                    if (subtitle case final subtitle?)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: QText.body(q.text2).copyWith(fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (action != null)
            Padding(
              padding: EdgeInsets.only(
                left: time.isNotEmpty || timeIcon != null ? 88 : 40,
                top: 8,
              ),
              child: action,
            ),
        ],
      ),
    );
    if (!current) return row;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        row,
        Positioned(
          left: -20,
          top: 10,
          bottom: 10,
          child: Container(width: 4, color: q.mark),
        ),
      ],
    );
  }
}

/// Círculo que se marca. Lleno y con check cuando está hecho.
class SheetCheck extends StatelessWidget {
  const SheetCheck({
    super.key,
    required this.done,
    this.busy = false,
    this.label,
    this.onTap,
  });

  final bool done;
  final bool busy;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final circle = AnimatedContainer(
      duration: context.motion(QMotion.fade),
      curve: QMotion.easeOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? q.text : Colors.transparent,
        border: Border.all(color: q.text, width: 2),
      ),
      child: busy
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: CircularProgressIndicator(strokeWidth: 2, color: q.text),
            )
          : done
          ? Icon(Icons.check_rounded, size: 16, color: q.card)
          : null,
    );
    return Semantics(
      button: onTap != null,
      checked: done,
      label: label,
      excludeSemantics: true,
      child: QuestlyPressable(
        onTap: onTap,
        radius: 24,
        decoration: const BoxDecoration(),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        child: Center(child: circle),
      ),
    );
  }
}

/// Píldora en tinta para la acción de una fila.
class SheetPill extends StatelessWidget {
  const SheetPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QuestlyPressable(
      onTap: onTap,
      radius: QRadius.button,
      semanticsLabel: label,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: onTap == null ? q.border : q.text,
        borderRadius: BorderRadius.circular(QRadius.button),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: QText.label(onTap == null ? q.text2 : q.card),
        ),
      ),
    );
  }
}
