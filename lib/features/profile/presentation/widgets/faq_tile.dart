import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

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
          style: TextStyle(
            color: context.lq.ink,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(color: context.lq.muted, fontSize: 9, height: 1.4),
          ),
        ],
      ),
    ),
  );
}
