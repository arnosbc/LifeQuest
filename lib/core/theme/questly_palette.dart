import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Todos los colores de un modo (claro u oscuro). Se lee con `context.q`.
@immutable
class QuestlyPalette extends ThemeExtension<QuestlyPalette> {
  const QuestlyPalette._({
    required this.dark,
    required this.bg,
    required this.card,
    required this.border,
    required this.track,
    required this.line,
    required this.text,
    required this.text2,
    required this.text3,
    required this.inputBorder,
    required this.ink,
    required this.tint,
    required this.coralInk,
    required this.coralTint,
    required this.mustardInk,
    required this.mustardTint,
    required this.river,
    required this.riverInk,
    required this.riverTint,
    required this.strong,
    required this.toastAction,
  });

  factory QuestlyPalette.of({required bool dark}) => QuestlyPalette._(
    dark: dark,
    bg: dark ? QColors.bgDark : QColors.bg,
    card: dark ? QColors.cardDark : QColors.card,
    border: dark ? QColors.borderDark : QColors.border,
    track: dark ? QColors.trackDark : QColors.track,
    line: dark ? QColors.borderDark : QColors.line,
    text: dark ? QColors.textDark : QColors.text,
    text2: dark ? QColors.text2Dark : QColors.text2,
    text3: dark ? const Color(0xFFD4D4D8) : QColors.text3,
    inputBorder: dark ? QColors.inputBorderDark : QColors.inputBorder,
    ink: dark ? QColors.accentInkDark : QColors.accentInk,
    tint: dark ? QColors.accentTintDark : QColors.accentTint,
    coralInk: dark ? const Color(0xFFFCA5A5) : QColors.coralInk,
    coralTint: dark ? const Color(0xFF2A1215) : QColors.coralTint,
    mustardInk: dark ? const Color(0xFFFCD34D) : QColors.mustardInk,
    mustardTint: dark ? const Color(0xFF2A2010) : QColors.mustardTint,
    river: dark ? const Color(0xFF93C5FD) : QColors.river,
    riverInk: dark ? const Color(0xFFBFDBFE) : QColors.riverInk,
    riverTint: dark ? const Color(0xFF172036) : QColors.riverTint,
    // Fondo de toast y filtro activo.
    strong: dark ? const Color(0xFFFAFAFA) : QColors.text,
    toastAction: dark ? QColors.accent : QColors.accentInkDark,
  );

  final bool dark;

  final Color bg, card, border, track, line, text, text2, text3, inputBorder;
  final Color ink, tint;
  final Color coralInk, coralTint, mustardInk, mustardTint;
  final Color river, riverInk, riverTint;
  final Color strong, toastAction;

  // Iguales en los dos modos.
  Color get accent => QColors.accent;
  Color get onAccent => Colors.white;
  Color get coral => QColors.coral;
  Color get mustard => QColors.mustard;
  Color get focus => QColors.focus;
  Color get disabled => QColors.disabled;
  Color get onStrong => dark ? QColors.bgDark : QColors.bg;
  Color get destructive => QColors.coralInk;
  Color get onDestructive => Colors.white;
  Color get toastShadow => const Color(0x2909090B);
  Color get segmentShadow => const Color(0x1A09090B);
  Color get sheetScrim => const Color(0x8009090B);
  Color get dialogScrim => const Color(0x9909090B);

  @override
  QuestlyPalette copyWith() => this;

  // Los cambios de modo son instantáneos: no se interpolan colores.
  @override
  QuestlyPalette lerp(QuestlyPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension QuestlyPaletteContext on BuildContext {
  /// Paleta del modo actual; la clara si el tema no la define.
  QuestlyPalette get q =>
      Theme.of(this).extension<QuestlyPalette>() ??
      QuestlyPalette.of(dark: false);

  /// Duración de una animación, en 0 si el sistema pide reducir movimiento.
  Duration motion(Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false ? Duration.zero : d;
}
