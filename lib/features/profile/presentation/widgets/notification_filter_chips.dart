import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/app_notification.dart';

/// `null` significa "Todas".
class NotificationFilterChips extends StatelessWidget {
  const NotificationFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final NotificationKind? selected;
  final ValueChanged<NotificationKind?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _filterChip('Todas', null),
        _filterChip('Crítica', NotificationKind.critical),
        _filterChip('Motivacional', NotificationKind.motivational),
        _filterChip('Informativa', NotificationKind.informative),
      ],
    ),
  );

  Widget _filterChip(String label, NotificationKind? filter) {
    final isSelected = selected == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(filter),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : LifeQuestColors.muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: Colors.white,
        selectedColor: LifeQuestColors.green,
        side: BorderSide(
          color: isSelected ? LifeQuestColors.green : LifeQuestColors.line,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}
