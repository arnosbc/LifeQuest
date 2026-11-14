import 'package:flutter/material.dart';

/// Fondo de la mascota de LifeQuest bajo un velo de [veil] para que el texto
/// mantenga el contraste AA. Lo usan todas las pestañas, incluida la Mazmorra.
class MascotBackground extends StatelessWidget {
  const MascotBackground({super.key, required this.veil, required this.child});

  /// Color del fondo del tema; se aplica al 82 % sobre la imagen.
  final Color veil;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: const AssetImage('assets/images/fondo_mascota.jpg'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          veil.withValues(alpha: 0.82),
          BlendMode.srcOver,
        ),
      ),
    ),
    child: child,
  );
}
