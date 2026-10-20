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
      IconButton(
        onPressed: onBack,
        tooltip: 'Volver',
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        color: context.lq.ink,
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}
