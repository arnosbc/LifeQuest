import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class CharacterCard extends StatelessWidget {
  const CharacterCard({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        CircleAvatar(
          radius: 31,
          backgroundColor: LifeQuestColors.green,
          child: Text(
            userName.isEmpty ? 'A' : userName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          userName,
          style: const TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: LifeQuestColors.softGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Nivel 24 · Estratega',
            style: TextStyle(
              color: LifeQuestColors.deepGreen,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
            ),
            Text(
              '7,850 / 12,000',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const LinearProgressIndicator(
          value: .65,
          minHeight: 5,
          color: LifeQuestColors.green,
          backgroundColor: Color(0xFFE3EEE7),
        ),
      ],
    ),
  );
}
