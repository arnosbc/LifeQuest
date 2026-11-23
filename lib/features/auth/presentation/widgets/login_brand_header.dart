import 'package:flutter/material.dart';

import 'package:proyecto_movil/features/auth/presentation/widgets/questly_brand.dart';

/// Encabezado del acceso: el logo de la app, su nombre y el lema, animados.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) => const QuestlyBrand(logo: 92);
}
