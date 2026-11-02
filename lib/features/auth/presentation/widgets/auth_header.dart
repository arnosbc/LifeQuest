import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Marca de Acceso: logo, «LifeQuest» y una bajada, centrados.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.subtitle, this.logoSize = 96});

  final String subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LifeQuestLogo(size: logoSize),
      const SizedBox(height: QSpace.s),
      LifeQuestWordmark(size: logoSize * .36),
      const SizedBox(height: QSpace.m),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: QText.body(context.q.text2).copyWith(fontSize: 14),
      ),
    ],
  );
}
