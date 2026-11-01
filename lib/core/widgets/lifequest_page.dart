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
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 28,
                height: 1.2,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(color: context.lq.muted, fontSize: 15)),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}
