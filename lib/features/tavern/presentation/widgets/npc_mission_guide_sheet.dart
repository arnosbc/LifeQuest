import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';

/// Guía de RPGenie para cumplir la misión de un NPC: objetivo, pasos o
/// ejercicios y pistas. El texto se puede seleccionar para copiarlo.
class NpcMissionGuideSheet extends StatelessWidget {
  const NpcMissionGuideSheet({
    super.key,
    required this.npcName,
    required this.mission,
  });

  final String npcName;
  final NpcMission mission;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    decoration: BoxDecoration(
      color: context.lq.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 8, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Misión de $npcName',
                  style: TextStyle(
                    color: context.lq.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, color: context.lq.ink),
            ),
          ],
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    color: context.lq.deepGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  mission.description ?? '',
                  style: TextStyle(
                    color: context.lq.ink,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Guía sugerida por RPGenie con IA. Puede equivocarse: '
                  'si algo no cuadra, compruébalo en tus apuntes.',
                  style: TextStyle(color: context.lq.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
