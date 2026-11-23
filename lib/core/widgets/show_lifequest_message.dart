import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

/// [actionLabel] + [onAction] añaden un botón (p. ej. «Deshacer»).
/// Con [replace] en false espera a que termine el mensaje que se ve.
void showLifeQuestMessage(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  bool replace = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (replace) messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: context.lq.background,
              onPressed: onAction,
            ),
      behavior: SnackBarBehavior.floating,
      // Casi negro en claro; en oscuro se invierte con su texto.
      backgroundColor: context.lq.ink,
    ),
  );
}
