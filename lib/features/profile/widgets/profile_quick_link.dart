import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class ProfileQuickLink extends StatelessWidget {
  const ProfileQuickLink({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showLifeQuestMessage(context, label),
    borderRadius: BorderRadius.circular(9),
    child: LifeQuestSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: LifeQuestColors.deepGreen, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
