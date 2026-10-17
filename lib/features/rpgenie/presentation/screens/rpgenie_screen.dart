import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class RpgenieScreen extends StatelessWidget {
  const RpgenieScreen({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestPage(
    title: 'RPGenie',
    subtitle: 'Tu siguiente paso, elegido para ti.',
    children: [
      LifeQuestSectionHeading('MISIÓN ACTUAL'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.auto_awesome,
        title: 'Preparar presentación del proyecto',
        subtitle: '🔴 Urgencia alta · vence hoy, 18:00',
        trailing: '+40 XP',
      ),
      SizedBox(height: 14),
      LifeQuestSectionHeading('CÓMO ELIJO TU MISIÓN'),
      SizedBox(height: 7),
      // RF-097: crítico → urgencia 🔴 > 🟡 > 🟢 → fecha límite más próxima.
      LifeQuestListRow(
        icon: Icons.priority_high_rounded,
        title: '1. Lo crítico primero',
        subtitle: 'Cualquier misión en estado crítico.',
      ),
      LifeQuestListRow(
        icon: Icons.traffic_outlined,
        title: '2. Después, la urgencia',
        subtitle: '🔴 alta, luego 🟡 media y 🟢 baja.',
      ),
      LifeQuestListRow(
        icon: Icons.event_outlined,
        title: '3. Por último, la fecha',
        subtitle: 'La fecha límite más próxima va primero.',
      ),
    ],
  );
}
