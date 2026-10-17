import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Encabezado con botón de volver de las subpáginas del perfil.
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: LifeQuestColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.chevron_left,
            color: LifeQuestColors.muted,
            size: 18,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: LifeQuestColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
