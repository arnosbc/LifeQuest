import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Hojas «¿Cómo funciona?» (PLAN-REDISENO §6, Momentos): XP, Constancia y
/// Monedas en lenguaje simple. Los números son las reglas del servidor
/// (`game_rules`); si cambian allí, se cambian aquí.
enum HowItWorks { xp, constancy, coins }

Future<void> showHowItWorks(BuildContext context, HowItWorks topic) {
  final (title, lines) = switch (topic) {
    HowItWorks.xp => (
      '¿Cómo funciona la XP?',
      const [
        'Cada tarea completada da entre 10 y 40 XP según su prioridad, su '
            'título y si está vinculada a un proyecto o a una meta.',
        'Las tareas con pasos reparten su XP entre ellos: cada paso suma.',
        'Para subir de nivel necesitas 100 × nivel^1,5 de XP. La XP nunca se '
            'gasta ni se pierde.',
        'Cada área sube de nivel con la XP de sus tareas y hábitos.',
      ],
    ),
    HowItWorks.constancy => (
      '¿Cómo funciona la Constancia?',
      const [
        'Mide qué tan constante vas. Empieza en 100.',
        'Sube +4 cada día que cumples al menos un hábito bueno.',
        'Baja con un mal hábito (−3, −5 u −8), un plazo vencido (−5) o un día '
            'sin actividad (−5).',
        'Por debajo de 30 ganas un 25 % menos de XP hasta recuperarla. Nunca '
            'pierdes nivel ni progreso.',
      ],
    ),
    HowItWorks.coins => (
      '¿Cómo funcionan las Monedas?',
      const [
        'Ganas Monedas junto con la XP: son el 30 % de la XP de cada tarea.',
        'Hay un tope suave al día para que la economía no se infle.',
        'Las gastas en Recompensas: descansos, protectores de racha y mejoras. '
            'Gastarlas nunca quita progreso.',
      ],
    ),
  };
  return showQuestlySheet<void>(
    context,
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: QSpace.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.q.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: QSpace.m),
                Expanded(child: Text(line, style: QText.body(context.q.text))),
              ],
            ),
          ),
      ],
    ),
  );
}
