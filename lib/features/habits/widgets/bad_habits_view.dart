import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class BadHabitsView extends StatelessWidget {
  const BadHabitsView({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const LifeQuestSurface(
        color: Color(0xFFFFF8F7),
        child: Row(
          children: [
            Icon(Icons.favorite_border, color: Color(0xFFE67777), size: 23),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Reconocer tus patrones te ayuda a cambiarlos. Registra cada día y sigue avanzando.',
                style: TextStyle(
                  color: LifeQuestColors.muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 13),
      const LifeQuestSectionHeading(
        'HÁBITOS QUE QUIERO EVITAR',
        action: '3 activos',
      ),
      const SizedBox(height: 7),
      _badHabit('Pantallas antes de dormir'),
      _badHabit('Café después de las 16:00'),
      _badHabit('Compras impulsivas'),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  showLifeQuestMessage(context, 'Recaída registrada.'),
              child: const Text('Registrar recaída'),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: FilledButton(
              onPressed: () => showLifeQuestMessage(context, '¡Día superado!'),
              style: FilledButton.styleFrom(
                backgroundColor: LifeQuestColors.green,
              ),
              child: const Text('Día superado'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      const LifeQuestSectionHeading('RESUMEN SEMANAL'),
      const SizedBox(height: 6),
      const Row(
        children: [
          Expanded(
            child: LifeQuestStat(value: '4 días', label: 'Sin recaídas'),
          ),
          SizedBox(width: 7),
          Expanded(
            child: LifeQuestStat(value: '1,250 XP', label: 'XP obtenida'),
          ),
        ],
      ),
    ],
  );

  Widget _badHabit(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: LifeQuestSurface(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: Color(0xFFE67777),
            size: 16,
          ),
          const SizedBox(width: 7),
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
          const Text(
            '0/7',
            style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}
