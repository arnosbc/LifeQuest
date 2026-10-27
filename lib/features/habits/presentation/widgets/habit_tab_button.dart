import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class HabitTabButton extends StatelessWidget {
  const HabitTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? context.lq.green : context.lq.surface,
        border: Border.all(
          color: selected ? context.lq.green : context.lq.line,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? context.lq.onDeepGreen : context.lq.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
