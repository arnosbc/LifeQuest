import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';

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
        _filterChip(context, 'Todas', null),
        _filterChip(context, 'Crítica', NotificationKind.critical),
        _filterChip(context, 'Motivacional', NotificationKind.motivational),
        _filterChip(context, 'Informativa', NotificationKind.informative),
      ],
    ),
  );

  Widget _filterChip(
    BuildContext context,
    String label,
    NotificationKind? filter,
  ) {
    final isSelected = selected == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(filter),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? context.lq.onDeepGreen : context.lq.muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: context.lq.surface,
        selectedColor: context.lq.green,
        side: BorderSide(
          color: isSelected ? context.lq.green : context.lq.line,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}
