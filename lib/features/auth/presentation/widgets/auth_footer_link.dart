import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// "¿Aún no tienes cuenta? Regístrate" y similares.
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
  Widget build(BuildContext context) {
    final q = context.q;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: QText.body(q.text2).copyWith(fontSize: 14)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: q.ink,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(48, 48),
          ),
          child: Text(linkLabel, style: QText.label(q.ink)),
        ),
      ],
    );
  }
}
