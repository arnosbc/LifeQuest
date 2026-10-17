import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class TavernScreen extends StatelessWidget {
  const TavernScreen({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestPage(
    title: 'Taverna',
    subtitle: 'Los personajes de tu reino tienen encargos para ti.',
    children: [
      LifeQuestSectionHeading('NPCs'),
      SizedBox(height: 7),
      // Cada NPC tiene una skill obligatoria; su misión es una tarea real.
      LifeQuestListRow(
        icon: Icons.sports_martial_arts,
        title: 'Entrenadora Vera · Salud',
        subtitle: 'Te propone: correr 5 km esta semana',
        trailing: 'Nueva',
      ),
      LifeQuestListRow(
        icon: Icons.local_library_outlined,
        title: 'Sabio Orión · Estudio',
        subtitle: 'Te propone: repasar el capítulo 3',
      ),
      LifeQuestListRow(
        icon: Icons.storefront_outlined,
        title: 'Mercader Brann · Trabajo',
        subtitle: 'Vuelve mañana: tendrá una nueva misión',
      ),
    ],
  );
}
