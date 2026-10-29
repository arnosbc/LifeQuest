import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/widgets/starfield_background.dart';

/// Fondo de las pantallas de la app: en tema oscuro, el espacio con estrellas;
/// en claro, el color de fondo del tema (el texto oscuro no se leería sobre
/// el espacio). [child] debe tener fondo transparente.
class SpaceBackdrop extends StatelessWidget {
  const SpaceBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Stack(
          fit: StackFit.expand,
          children: [const StarfieldBackground(), child],
        )
      : ColoredBox(color: context.lq.background, child: child);
}
