import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

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
      Text(question, style: TextStyle(color: context.lq.muted, fontSize: 13)),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: context.lq.deepGreen,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(48, 48),
        ),
        child: Text(
          linkLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
