import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Roles de color con nombres de las pantallas anteriores, calculados desde
/// la paleta (`context.q`) de cada modo.
@immutable
class LifeQuestPalette extends ThemeExtension<LifeQuestPalette> {
  const LifeQuestPalette({
    required this.green,
    required this.deepGreen,
    required this.onDeepGreen,
    required this.ink,
    required this.muted,
    required this.background,
    required this.surface,
    required this.line,
    required this.softGreen,
    required this.outline,
    required this.error,
    required this.warning,
  });

  factory LifeQuestPalette.fromQuestly(QuestlyPalette q) => LifeQuestPalette(
    green: q.accent,
    deepGreen: q.ink,
    onDeepGreen: q.dark ? q.bg : Colors.white,
    ink: q.text,
    muted: q.text2,
    background: q.bg,
    surface: q.card,
    line: q.border,
    softGreen: q.tint,
    outline: q.inputBorder,
    error: q.coralInk,
    warning: q.coral,
  );

  final Color green;
  final Color deepGreen;
  final Color onDeepGreen;
  final Color ink;
  final Color muted;
  final Color background;
  final Color surface;
  final Color line;
  final Color softGreen;
  final Color outline;
  final Color error;
  final Color warning;

  static final light = LifeQuestPalette.fromQuestly(
    QuestlyPalette.of(dark: false),
  );
  static final dark = LifeQuestPalette.fromQuestly(
    QuestlyPalette.of(dark: true),
  );

  @override
  LifeQuestPalette copyWith() => this;

  @override
  LifeQuestPalette lerp(LifeQuestPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return LifeQuestPalette(
      green: c(green, other.green),
      deepGreen: c(deepGreen, other.deepGreen),
      onDeepGreen: c(onDeepGreen, other.onDeepGreen),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      line: c(line, other.line),
      softGreen: c(softGreen, other.softGreen),
      outline: c(outline, other.outline),
      error: c(error, other.error),
      warning: c(warning, other.warning),
    );
  }
}

extension LifeQuestPaletteContext on BuildContext {
  /// Paleta del tema actual; cae en la clara si el tema no la define.
  LifeQuestPalette get lq =>
      Theme.of(this).extension<LifeQuestPalette>() ?? LifeQuestPalette.light;
}

abstract final class LifeQuestTheme {
  /// Tema del modo con las dos paletas: `context.q` y `context.lq`.
  static ThemeData build({required bool dark}) {
    final q = QuestlyPalette.of(dark: dark);
    final base = questlyTheme(dark: dark);
    return base.copyWith(
      // Hojas, diálogos y avisos de Material sin color propio siguen al tema.
      colorScheme: base.colorScheme.copyWith(
        surfaceContainerLow: q.card,
        surfaceContainer: q.card,
        surfaceContainerHigh: q.card,
        outlineVariant: q.border,
        inverseSurface: q.strong,
        onInverseSurface: q.onStrong,
      ),
      dividerColor: q.border,
      extensions: [q, LifeQuestPalette.fromQuestly(q)],
    );
  }

  static final light = build(dark: false);
  static final dark = build(dark: true);
}
