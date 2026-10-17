import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class HelpResourceTile extends StatelessWidget {
  const HelpResourceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: InkWell(
      onTap: () => _showResource(context),
      borderRadius: BorderRadius.circular(9),
      child: LifeQuestSurface(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            LifeQuestIconTile(icon, size: 22),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: LifeQuestColors.muted,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: LifeQuestColors.muted,
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );

  void _showResource(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(subtitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
