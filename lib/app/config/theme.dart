import 'package:flutter/material.dart';

/// Paleta fija (tema claro). Las pantallas aún no migradas la usan directamente;
/// las migradas leen `context.lq`, que cambia con el tema claro/oscuro.
abstract final class LifeQuestColors {
  static const green = Color(0xFF29B951);
  // deepGreen y muted ajustados para ≥4.5:1 sobre background (WCAG AA).
  static const deepGreen = Color(0xFF137A34);
  static const ink = Color(0xFF1D3B2B);
  static const muted = Color(0xFF5E6E64);
  static const background = Color(0xFFF4F9F6);
  static const line = Color(0xFFD5EBDD);
  static const softGreen = Color(0xFFE8F7EC);
  // Borde de controles (campos, casillas): ≥3:1 sobre blanco y fondo.
  static const outline = Color(0xFF6F8A78);
  // Errores de validación: ≥4.5:1 sobre background.
  static const error = Color(0xFFB23A3A);
}

/// Los mismos roles de color, con valores para tema claro y oscuro.
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
  });

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

  static const light = LifeQuestPalette(
    green: LifeQuestColors.green,
    deepGreen: LifeQuestColors.deepGreen,
    onDeepGreen: Colors.white,
    ink: LifeQuestColors.ink,
    muted: LifeQuestColors.muted,
    background: LifeQuestColors.background,
    surface: Colors.white,
    line: LifeQuestColors.line,
    softGreen: LifeQuestColors.softGreen,
    outline: LifeQuestColors.outline,
    error: LifeQuestColors.error,
  );

  // Mismos contrastes AA que el tema claro, sobre background y surface oscuros.
  static const dark = LifeQuestPalette(
    green: Color(0xFF3FCB67),
    deepGreen: Color(0xFF5BD47E),
    onDeepGreen: Color(0xFF0A2413),
    ink: Color(0xFFE3EEE7),
    muted: Color(0xFFA3B3A9),
    background: Color(0xFF0F1612),
    surface: Color(0xFF17211B),
    line: Color(0xFF2A3A31),
    softGreen: Color(0xFF1D3326),
    outline: Color(0xFF7E9A88),
    error: Color(0xFFF28B82),
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
    );
  }
}

extension LifeQuestPaletteContext on BuildContext {
  /// Paleta del tema actual; cae en la clara si el tema no la define.
  LifeQuestPalette get lq =>
      Theme.of(this).extension<LifeQuestPalette>() ?? LifeQuestPalette.light;
}

abstract final class LifeQuestTheme {
  static ThemeData _build(Brightness brightness, LifeQuestPalette p) =>
      ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: LifeQuestColors.green,
          brightness: brightness,
        ),
        scaffoldBackgroundColor: p.background,
        extensions: [p],
      );

  static final light = _build(Brightness.light, LifeQuestPalette.light);
  static final dark = _build(Brightness.dark, LifeQuestPalette.dark);

  /// shortcut: fuerza el tema claro en pantallas que aún usan LifeQuestColors
  /// fijos (sobre fondo oscuro su texto sería ilegible); quitar al migrarlas.
  static Widget lightOnly(Widget child) => Theme(data: light, child: child);
}
