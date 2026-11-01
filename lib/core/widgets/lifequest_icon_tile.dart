import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

class LifeQuestIconTile extends StatelessWidget {
  const LifeQuestIconTile(this.icon, {super.key, this.size = 34});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Icon(icon, color: context.lq.ink, size: size * .6),
  );
}
