import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';

/// "¿No tienes cuenta? Crea tu perfil" y similares.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.question,
    required this.linkLabel,
    required this.onTap,
  });

  final String question;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        question,
        style: const TextStyle(color: LifeQuestColors.muted, fontSize: 10),
      ),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: LifeQuestColors.deepGreen,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          linkLabel,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
