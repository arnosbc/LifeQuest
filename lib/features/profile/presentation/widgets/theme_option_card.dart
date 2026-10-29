import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';

String themeLabel(ThemePreference theme) => switch (theme) {
  ThemePreference.light => 'Claro',
  ThemePreference.dark => 'Oscuro',
  ThemePreference.system => 'Sistema',
};

/// Opción de tema con una miniatura pintada con la paleta real.
class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ThemePreference theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final shape = RoundedRectangleBorder(
      side: BorderSide(
        color: selected ? lq.deepGreen : lq.line,
        width: selected ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(11),
    );
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: 'Tema ${themeLabel(theme)}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: lq.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: SizedBox(
                    height: 76,
                    child: switch (theme) {
                      ThemePreference.light => _Miniature(
                        LifeQuestPalette.light,
                      ),
                      ThemePreference.dark => _Miniature(LifeQuestPalette.dark),
                      ThemePreference.system => Row(
                        children: [
                          Expanded(child: _Miniature(LifeQuestPalette.light)),
                          Expanded(child: _Miniature(LifeQuestPalette.dark)),
                        ],
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? lq.deepGreen : lq.outline,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        themeLabel(theme),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: lq.ink,
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de perfil en miniatura: título, detalle y barra de XP.
class _Miniature extends StatelessWidget {
  const _Miniature(this.p);

  final LifeQuestPalette p;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: p.background,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.line),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bar(p.ink, .75, 5),
              const SizedBox(height: 5),
              _bar(p.muted, .5, 4),
              const Spacer(),
              _bar(p.green, .85, 5),
            ],
          ),
        ),
      ),
    ),
  );

  static Widget _bar(Color color, double width, double height) =>
      FractionallySizedBox(
        widthFactor: width,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      );
}
