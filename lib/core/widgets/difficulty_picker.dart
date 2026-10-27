import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/entities/difficulty.dart';

/// Opciones de dificultad con su efecto (XP y vida perdida). Lo usan el
/// Onboarding y Configuración.
class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<DifficultyOption> options;
  final GameDifficulty selected;

  /// Null deshabilita las opciones (p. ej. mientras se guarda).
  final ValueChanged<GameDifficulty>? onSelected;

  /// Si las Monedas no cambian entre niveles, basta con decirlo una vez.
  static bool sameCoins(List<DifficultyOption> options) =>
      options.map((o) => o.coinMultiplier).toSet().length <= 1;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final coins = !sameCoins(options);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options) ...[
          Semantics(
            selected: option.level == selected,
            button: true,
            child: Material(
              color: option.level == selected ? lq.softGreen : lq.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
                side: BorderSide(
                  color: option.level == selected ? lq.deepGreen : lq.line,
                  width: option.level == selected ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: onSelected == null
                    ? null
                    : () => onSelected!(option.level),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              difficultyName(option.level),
                              style: TextStyle(
                                color: lq.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'XP ${multiplier(option.xpMultiplier)} · '
                              'Vida perdida ${multiplier(option.hpPenaltyMultiplier)}'
                              '${coins ? ' · Monedas ${multiplier(option.coinMultiplier)}' : ''}',
                              style: TextStyle(color: lq.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (option.level == selected)
                        Icon(Icons.check_circle_rounded, color: lq.deepGreen),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

String difficultyName(GameDifficulty level) => switch (level) {
  GameDifficulty.easy => 'Fácil',
  GameDifficulty.normal => 'Normal',
  GameDifficulty.hard => 'Difícil',
};

/// ×1,2 · ×1 · ×0,85 (coma decimal).
String multiplier(double value) =>
    '×${value == value.roundToDouble() ? value.toInt() : value}'.replaceAll(
      '.',
      ',',
    );
