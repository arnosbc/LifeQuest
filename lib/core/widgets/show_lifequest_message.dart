import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

void showLifeQuestMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        // Tinta de Musgo en claro; en oscuro se invierte con su texto.
        backgroundColor: context.lq.ink,
      ),
    );
}
