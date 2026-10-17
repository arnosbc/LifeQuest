import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class CompletionRateCard extends StatelessWidget {
  const CompletionRateCard({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasa de finalización 76%',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '38/50',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
            ),
          ],
        ),
        SizedBox(height: 6),
        LinearProgressIndicator(
          value: .76,
          minHeight: 5,
          color: LifeQuestColors.green,
          backgroundColor: Color(0xFFE3EEE7),
        ),
      ],
    ),
  );
}
