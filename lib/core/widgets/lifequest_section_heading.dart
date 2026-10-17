import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

class LifeQuestSectionHeading extends StatelessWidget {
  const LifeQuestSectionHeading(
    this.title, {
    super.key,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64786B),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (action != null)
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
            child: Text(
              action!,
              style: const TextStyle(
                color: LifeQuestColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  );
}
