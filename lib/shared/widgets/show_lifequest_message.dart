import 'package:flutter/material.dart';

import 'lifequest_colors.dart';

void showLifeQuestMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: LifeQuestColors.ink,
      ),
    );
}
