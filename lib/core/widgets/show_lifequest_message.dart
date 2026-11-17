import 'package:flutter/material.dart';

void showLifeQuestMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        // Sin color propio: usa inverseSurface/onInverseSurface del tema
        // (strong/onStrong), legible en claro y en oscuro.
      ),
    );
}
