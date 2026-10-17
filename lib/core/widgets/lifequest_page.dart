import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

class LifeQuestPage extends StatelessWidget {
  const LifeQuestPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(19, 17, 19, 22),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: LifeQuestColors.muted, fontSize: 11),
      ),
      const SizedBox(height: 17),
      ...children,
    ],
  );
}
