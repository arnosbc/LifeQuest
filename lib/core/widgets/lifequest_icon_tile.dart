import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

class LifeQuestIconTile extends StatelessWidget {
  const LifeQuestIconTile(this.icon, {super.key, this.size = 34});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.lq.softGreen,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, color: context.lq.deepGreen, size: size * .55),
  );
}
