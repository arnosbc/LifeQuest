import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class DungeonTimerRing extends StatelessWidget {
  const DungeonTimerRing({
    super.key,
    required this.remaining,
    required this.total,
    required this.label,
    required this.footer,
  });

  final Duration remaining;
  final Duration total;

  /// "MAZMORRA ACTIVA", "DESCANSO" o "EN PAUSA".
  final String label;

  /// Línea inferior, p. ej. "Ciclo 2 de 4".
  final String footer;

  @override
  Widget build(BuildContext context) {
    final seconds = remaining.inSeconds;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return Center(
      child: Semantics(
        label: '$label. Quedan ${seconds ~/ 60} minutos. $footer',
        excludeSemantics: true,
        child: SizedBox(
          width: 184,
          height: 184,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: total.inSeconds == 0
                      ? 0
                      : remaining.inSeconds / total.inSeconds,
                  strokeWidth: 5,
                  backgroundColor: context.lq.line,
                  color: context.lq.deepGreen,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TIEMPO RESTANTE',
                    style: TextStyle(color: context.lq.muted, fontSize: 9),
                  ),
                  Text(
                    '$mm:$ss',
                    style: TextStyle(
                      color: context.lq.ink,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.lq.softGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: context.lq.deepGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    footer,
                    style: TextStyle(color: context.lq.muted, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
