import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFDFF8E8),
              child: Text(
                userName.isEmpty ? 'A' : userName[0].toUpperCase(),
                style: const TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: LifeQuestColors.softGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NIVEL 24',
                      style: TextStyle(
                        color: LifeQuestColors.deepGreen,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.more_horiz,
              color: LifeQuestColors.muted,
              size: 17,
            ),
            const SizedBox(width: 5),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESO XP',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 7),
            ),
            Text(
              '1,450 / 2,000 XP',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const LinearProgressIndicator(
          value: .72,
          minHeight: 4,
          color: LifeQuestColors.green,
          backgroundColor: Color(0xFFE3EEE7),
        ),
      ],
    ),
  );
}
