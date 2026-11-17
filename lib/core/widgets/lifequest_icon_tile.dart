import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

class LifeQuestIconTile extends StatelessWidget {
  const LifeQuestIconTile(IconData this.icon, {super.key, this.size = 34});

  /// La cara de Nevi: el icono del Asistente (decisión del usuario 2026-11-15).
  const LifeQuestIconTile.nevi({super.key, this.size = 34}) : icon = null;

  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.lq.softGreen,
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: switch (icon) {
      final IconData i => Icon(
        i,
        color: context.lq.deepGreen,
        size: size * .55,
      ),
      // Decorativa: el texto de al lado ya dice que es el Asistente.
      null => Image.asset(
        'assets/images/mascota/nevi_cara.webp',
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      ),
    },
  );
}
