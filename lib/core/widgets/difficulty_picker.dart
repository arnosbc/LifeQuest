import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/sheet_row.dart';

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

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    // Filas de la hoja, como un grupo de radio: la elegida en negrita con su
    // check en tinta; nada de tarjetas dentro de la hoja.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options)
          Semantics(
            selected: option.level == selected,
            inMutuallyExclusiveGroup: true,
            button: true,
            child: InkWell(
              onTap: onSelected == null
                  ? null
                  : () => onSelected!(option.level),
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: lq.line)),
                ),
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
                              fontWeight: option.level == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'XP ${multiplier(option.xpMultiplier)}',
                            style: TextStyle(color: lq.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    SheetCheck(done: option.level == selected),
                  ],
                ),
              ),
            ),
          ),
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
