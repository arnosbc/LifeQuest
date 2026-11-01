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
    text3: dark ? const Color(0xFFD6D3CC) : QColors.text3,
    inputBorder: dark ? QColors.inputBorderDark : QColors.inputBorder,
    ink: dark ? QColors.textDark : QColors.text,
    tint: dark ? QColors.trackDark : QColors.track,
    coralInk: dark ? QColors.markDark : QColors.coralInk,
    coralTint: dark ? const Color(0xFF3A1517) : QColors.coralTint,
    mustardInk: dark ? const Color(0xFFF5C26B) : QColors.mustardInk,
    mustardTint: dark ? const Color(0xFF33270F) : QColors.mustardTint,
    river: dark ? const Color(0xFF8FB0F0) : QColors.river,
    riverInk: dark ? const Color(0xFFB9CCF5) : QColors.riverInk,
    riverTint: dark ? const Color(0xFF1A2440) : QColors.riverTint,
    // Fondo de toast y filtro activo.
    strong: dark ? QColors.textDark : QColors.text,
    toastAction: dark ? QColors.mark : QColors.markDark,
  );

  final bool dark;

  final Color bg, card, border, track, line, text, text2, text3, inputBorder;
  final Color ink, tint;
  final Color coralInk, coralTint, mustardInk, mustardTint;
  final Color river, riverInk, riverTint;
  final Color strong, toastAction;

  /// Acciones en tinta (botones, enlaces, progreso).
  Color get accent => text;
  Color get onAccent => card;

  /// El único rojo: la fecha, la tarea en curso y «ahora».
  Color get mark => dark ? QColors.markDark : QColors.mark;

  // Iguales en los dos modos.
  Color get coral => QColors.coral;
  Color get mustard => QColors.mustard;
  Color get focus => QColors.focus;
  Color get disabled => QColors.disabled;
  Color get onStrong => dark ? QColors.bgDark : QColors.bg;
  Color get destructive => QColors.coralInk;
  Color get onDestructive => Colors.white;
  Color get toastShadow => const Color(0x29111111);
  Color get segmentShadow => const Color(0x1A111111);
  Color get sheetScrim => const Color(0x80111111);
  Color get dialogScrim => const Color(0x99111111);

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
