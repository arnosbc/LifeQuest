import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.accents,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> accents;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (final color in accents) _accentDot(color)],
    ),
  );

  Widget _accentDot(Color color) {
    final isSelected = color == selected;
    return InkWell(
      onTap: () => onSelected(color),
      customBorder: const CircleBorder(),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
