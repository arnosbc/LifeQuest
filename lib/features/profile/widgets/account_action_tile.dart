import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class AccountActionTile extends StatelessWidget {
  const AccountActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: LifeQuestSurface(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: LifeQuestColors.deepGreen, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: LifeQuestColors.muted,
              size: 17,
            ),
          ],
        ),
      ),
    ),
  );
}
