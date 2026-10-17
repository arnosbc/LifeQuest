import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

class SignOutCard extends StatelessWidget {
  const SignOutCard({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestSurface(
    padding: EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tu progreso está guardado de forma segura en la nube. Puedes volver a entrar cuando quieras.',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 8,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}
