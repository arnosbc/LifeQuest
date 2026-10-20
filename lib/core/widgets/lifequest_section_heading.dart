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
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              color: context.lq.muted,
              fontSize: 12,
              letterSpacing: .6,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: context.lq.deepGreen,
            disabledForegroundColor: context.lq.deepGreen,
            minimumSize: const Size(48, 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(action!),
        ),
    ],
  );
}
