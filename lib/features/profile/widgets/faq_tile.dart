import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class FaqTile extends StatelessWidget {
  const FaqTile({super.key, required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: LifeQuestSurface(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 9),
        childrenPadding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
        title: Text(
          question,
          style: const TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: LifeQuestColors.muted,
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}
