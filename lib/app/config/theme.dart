import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';

/// Paleta fija (Bosque claro de «Bosque vivo»). Las pantallas aún no migradas
/// la usan directamente; las migradas leen `context.lq` o `context.q`.
abstract final class LifeQuestColors {
  static const green = Color(0xFF2E7D4F);
  static const deepGreen = Color(0xFF1F5C39);
  static const ink = QColors.text;
  static const muted = QColors.text2;
  static const background = QColors.bg;
  static const line = QColors.border;
  static const softGreen = Color(0xFFE1F0E6);
  static const outline = QColors.inputBorder;
  static const error = QColors.coralInk;
  // Pérdida de HP y malos hábitos: solo relleno o iconos, nunca texto pequeño.
  static const warning = QColors.coral;
}

/// Roles de color de las pantallas anteriores al rediseño, calculados desde
/// los tokens Questly (docs/diseño/PLAN-REDISENO.md §3) para cada modo y tema.
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
    QuestlyPalette.of(QuestlyRealm.bosque, dark: false),
  );
  static final dark = LifeQuestPalette.fromQuestly(
    QuestlyPalette.of(QuestlyRealm.bosque, dark: true),
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

/// El dominio no conoce el tema visual: aquí se traduce el tema guardado.
QuestlyRealm questlyRealmOf(ThemeRealm realm) => switch (realm) {
  ThemeRealm.bosque => QuestlyRealm.bosque,
  ThemeRealm.rio => QuestlyRealm.rio,
  ThemeRealm.brasa => QuestlyRealm.brasa,
  ThemeRealm.oro => QuestlyRealm.oro,
};

abstract final class LifeQuestTheme {
  /// Tema Questly del modo y tema del reino, con las dos paletas: la nueva
  /// (`context.q`) y la de las pantallas aún no migradas (`context.lq`).
  static ThemeData build(QuestlyRealm realm, {required bool dark}) {
    final q = QuestlyPalette.of(realm, dark: dark);
    final base = questlyTheme(realm: realm, dark: dark);
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

  static final light = build(QuestlyRealm.bosque, dark: false);
  static final dark = build(QuestlyRealm.bosque, dark: true);

  /// shortcut: fuerza el tema claro en pantallas que aún usan LifeQuestColors
  /// fijos (sobre fondo oscuro su texto sería ilegible); quitar al migrarlas.
  static Widget lightOnly(Widget child) => Theme(data: light, child: child);
}
