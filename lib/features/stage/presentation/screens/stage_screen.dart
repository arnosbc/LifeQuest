import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Stage · P.A.R.A.: pantalla de lectura sobre tareas, proyectos, skills y
/// recursos. No guarda datos propios.
class StageScreen extends StatelessWidget {
  const StageScreen({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestPage(
    title: 'Stage · P.A.R.A.',
    subtitle: 'Tu centro de mando, todo en un vistazo.',
    children: [
      // RF-089: orden fijo urgent → high → medium → low → pending.
      LifeQuestSectionHeading('DAILY HIGHLIGHT'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.bolt,
        title: 'Urgente',
        subtitle: 'Enviar informe mensual · vence en 5 h',
      ),
      LifeQuestListRow(
        icon: Icons.flag_outlined,
        title: 'Alta',
        subtitle: 'Preparar presentación del proyecto',
      ),
      LifeQuestListRow(
        icon: Icons.hourglass_empty_rounded,
        title: 'Pendiente',
        subtitle: 'Revisión del diseño · delegada a Laura',
      ),
      SizedBox(height: 14),
      LifeQuestSectionHeading('PROYECTOS'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.work_outline,
        title: 'Lanzamiento de la app',
        subtitle: 'Trabajo · 6 de 10 tareas',
        trailing: '🔴',
      ),
      LifeQuestListRow(
        icon: Icons.school_outlined,
        title: 'Curso de inglés',
        subtitle: 'No area assigned',
        trailing: '🟢',
      ),
      SizedBox(height: 14),
      LifeQuestSectionHeading('ÁREAS (SKILLS)'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.fitness_center,
        title: 'Salud',
        subtitle: '3 hábitos · 2 tareas abiertas',
        trailing: 'Nv 4',
      ),
      LifeQuestListRow(
        icon: Icons.menu_book_rounded,
        title: 'Estudio',
        subtitle: '1 proyecto · 4 tareas abiertas',
        trailing: 'Nv 6',
      ),
      SizedBox(height: 14),
      LifeQuestSectionHeading('RECURSOS'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.bookmark_border,
        title: 'Guía de presentaciones',
        subtitle: 'Enlace guardado desde el Brain Dump',
      ),
    ],
  );
}
