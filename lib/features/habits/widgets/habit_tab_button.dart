import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

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
        color: selected ? LifeQuestColors.green : Colors.white,
        border: Border.all(
          color: selected ? LifeQuestColors.green : LifeQuestColors.line,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : LifeQuestColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
