// Tokens de «Bosque vivo» que no trae questly_theme.dart (copia exacta de
// docs/diseño/tokens). Valores de DESIGN.md §2, questly.css y Hero.dc.html;
// ver docs/diseño/PLAN-REDISENO.md §3.

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Colores del paisaje de la cabecera (Hero.dc.html).
@immutable
class QHeroTone {
  const QHeroTone({
    required this.bg,
    required this.sun,
    required this.hill1,
    required this.hill2,
    required this.trees,
    required this.kicker,
  });

  final Color bg, sun, hill1, hill2, trees, kicker;

  static const forest = QHeroTone(
    bg: Color(0xFF1F5C39),
    sun: Color(0xFFF2C66B),
    hill1: Color(0xFF2E7D4F),
    hill2: Color(0xFF276B44),
    trees: Color(0xFF174A2E),
    kicker: Color(0xFFCFE8D7),
  );
  static const river = QHeroTone(
    bg: Color(0xFF24396B),
    sun: Color(0xFFF2C66B),
    hill1: Color(0xFF3C5BA8),
    hill2: Color(0xFF31498A),
    trees: Color(0xFF1A2A52),
    kicker: Color(0xFFD3DDF4),
  );
  static const ember = QHeroTone(
    bg: Color(0xFF7A2716),
    sun: Color(0xFFF2C66B),
    hill1: Color(0xFFA8361F),
    hill2: Color(0xFF922F1B),
    trees: Color(0xFF5A1C10),
    kicker: Color(0xFFF7D5CC),
  );
  static const gold = QHeroTone(
    bg: Color(0xFF5C4100),
    sun: Color(0xFFFBF0D3),
    hill1: Color(0xFF8A6200),
    hill2: Color(0xFF765400),
    trees: Color(0xFF3F2D00),
    kicker: Color(0xFFF5E3B0),
  );
  static const night = QHeroTone(
    bg: Color(0xFF0E1B14),
    sun: Color(0xFFE9EFE6),
    hill1: Color(0xFF1C2C24),
    hill2: Color(0xFF16241D),
    trees: Color(0xFF0B140F),
    kicker: Color(0xFF9FDCB4),
  );

  static QHeroTone of(QuestlyRealm realm) => switch (realm) {
    QuestlyRealm.bosque => forest,
    QuestlyRealm.rio => river,
    QuestlyRealm.brasa => ember,
    QuestlyRealm.oro => gold,
  };

  // Comunes a todos los tonos.
  static const text = Color(0xFFF3F6EF);
  static const actionBg = Color(0x24F3F6EF); // rgba(243,246,239,.14)
  static const badgeBg = Color(0xFFF2C66B);
  static const badgeText = Color(0xFF1A1F1B);
}

/// Todos los colores de un modo + tema del reino. Se lee con `context.q`.
@immutable
class QuestlyPalette extends ThemeExtension<QuestlyPalette> {
  const QuestlyPalette._({
    required this.realm,
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
    required this.accent,
    required this.onAccent,
    required this.ink,
    required this.tint,
    required this.buttonShadow,
    required this.tonalBorder,
    required this.cardShadow,
    required this.coralInk,
    required this.coralTint,
    required this.mustardInk,
    required this.mustardTint,
    required this.river,
    required this.riverInk,
    required this.riverTint,
    required this.strong,
    required this.toastAction,
    required this.hero,
  });

  factory QuestlyPalette.of(QuestlyRealm realm, {required bool dark}) {
    final r = QRealm.of(realm);
    return QuestlyPalette._(
      realm: realm,
      dark: dark,
      bg: dark ? QColors.bgDark : QColors.bg,
      card: dark ? QColors.cardDark : QColors.card,
      border: dark ? QColors.borderDark : QColors.border,
      track: dark ? QColors.trackDark : QColors.track,
      line: dark ? const Color(0xFF24362C) : QColors.line,
      text: dark ? QColors.textDark : QColors.text,
      text2: dark ? QColors.text2Dark : QColors.text2,
      text3: dark ? const Color(0xFFCFDACF) : QColors.text3,
      inputBorder: dark ? QColors.inputBorderDark : QColors.inputBorder,
      accent: r.accent,
      onAccent: r.onAccent,
      ink: dark ? r.inkDark : r.ink,
      tint: dark ? r.tintDark : r.tint,
      // questly.css: sombra del botón principal según el tema.
      buttonShadow: switch (realm) {
        QuestlyRealm.bosque => const Color(0xFF1F5C39),
        QuestlyRealm.rio => const Color(0xFF24396B),
        QuestlyRealm.brasa => const Color(0xFF7A2716),
        QuestlyRealm.oro => const Color(0xFF8A6200),
      },
      tonalBorder: realm == QuestlyRealm.oro
          ? const Color(0xFFB9890F)
          : r.accent,
      cardShadow: dark ? const Color(0xFF0B140F) : QColors.border,
      coralInk: dark ? const Color(0xFFF5B8A8) : QColors.coralInk,
      coralTint: dark ? const Color(0xFF3A1F1A) : QColors.coralTint,
      mustardInk: dark ? const Color(0xFFF5D896) : QColors.mustardInk,
      mustardTint: dark ? const Color(0xFF3A3016) : QColors.mustardTint,
      river: dark ? const Color(0xFF9FB8E8) : QColors.river,
      riverInk: dark ? const Color(0xFFB9CBF0) : QColors.riverInk,
      riverTint: dark ? const Color(0xFF1E2A44) : QColors.riverTint,
      // Fondo de toast y filtro activo (#1E2A22, en oscuro #2C4036).
      strong: dark ? const Color(0xFF2C4036) : QColors.text,
      toastAction: r.inkDark,
      hero: dark ? QHeroTone.night : QHeroTone.of(realm),
    );
  }

  final QuestlyRealm realm;
  final bool dark;

  final Color bg, card, border, track, line, text, text2, text3, inputBorder;
  final Color accent, onAccent, ink, tint;
  final Color buttonShadow, tonalBorder, cardShadow;
  final Color coralInk, coralTint, mustardInk, mustardTint;
  final Color river, riverInk, riverTint;
  final Color strong, toastAction;
  final QHeroTone hero;

  // Iguales en todos los modos y temas.
  Color get coral => QColors.coral;
  Color get mustard => QColors.mustard;
  Color get boss => QColors.boss;
  Color get focus => QColors.focus;
  Color get disabled => QColors.disabled;
  Color get onStrong => QColors.bg;
  Color get destructive => QColors.coralInk;
  Color get destructiveShadow => const Color(0xFF7A2716);
  Color get onDestructive => Colors.white;
  Color get toastShadow => const Color(0x381E2A22); // rgba(30,42,34,.22)
  Color get segmentShadow => const Color(0x1F1E2A22); // rgba(30,42,34,.12)
  Color get sheetScrim => const Color(0x80122218); // rgba(18,34,24,.5)
  Color get dialogScrim => const Color(0x99122218); // rgba(18,34,24,.6)

  @override
  QuestlyPalette copyWith() => this;

  // Los cambios de tema son instantáneos: no se interpolan colores.
  @override
  QuestlyPalette lerp(QuestlyPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension QuestlyPaletteContext on BuildContext {
  /// Paleta Questly del tema actual; Bosque claro si el tema no la define.
  QuestlyPalette get q =>
      Theme.of(this).extension<QuestlyPalette>() ??
      QuestlyPalette.of(QuestlyRealm.bosque, dark: false);

  /// Duración de una animación, en 0 si el sistema pide reducir movimiento.
  Duration motion(Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false ? Duration.zero : d;
}
