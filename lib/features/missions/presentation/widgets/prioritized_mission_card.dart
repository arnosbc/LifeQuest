import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class PrioritizedMissionCard extends StatelessWidget {
  const PrioritizedMissionCard({
    super.key,
    required this.started,
    required this.onToggleStart,
  });

  final bool started;
  final VoidCallback onToggleStart;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('MISIÓN PRIORIZADA', style: TextStyle(color: LifeQuestColors.deepGreen, fontSize: 10, fontWeight: FontWeight.w800)),
        Icon(Icons.shield_outlined, color: LifeQuestColors.green, size: 19),
      ]),
      const SizedBox(height: 11),
      const Text('Preparar presentación del proyecto', style: TextStyle(color: LifeQuestColors.ink, fontSize: 20, height: 1.2, fontWeight: FontWeight.w800)),
      const SizedBox(height: 13),
      _detail('Origen', 'Objetivo principal'),
      _detail('Urgencia', 'Alta'),
      _detail('Fecha límite', 'Hoy · 18:00'),
      const Divider(height: 20),
      _detail('Recompensa', '350 XP    ·    120 monedas'),
      const SizedBox(height: 9),
      SizedBox(width: double.infinity, height: 42, child: FilledButton.icon(
        onPressed: onToggleStart,
        icon: Icon(started ? Icons.check : Icons.play_arrow_rounded),
        label: Text(started ? 'Misión iniciada' : 'Iniciar misión'),
        style: FilledButton.styleFrom(backgroundColor: LifeQuestColors.green),
      )),
    ]),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: LifeQuestColors.muted, fontSize: 11))),
      Text(value, style: const TextStyle(color: LifeQuestColors.deepGreen, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}
