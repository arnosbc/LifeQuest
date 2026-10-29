// Questly · tokens del sistema «Bosque vivo» para Flutter.
// Generado desde DESIGN.md. Copiar a lib/theme/questly_theme.dart
// Requiere el paquete google_fonts (Bricolage Grotesque, DM Sans, DM Mono).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum QuestlyRealm { bosque, rio, brasa, oro }

class QColors {
  // Neutros claro
  static const bg = Color(0xFFF3F6EF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE4D4);
  static const track = Color(0xFFE7EDE1);
  static const line = Color(0xFFEEF2EA);
  static const text = Color(0xFF1E2A22);
  static const text2 = Color(0xFF4E5C52);
  static const text3 = Color(0xFF3E4A42);
  static const inputBorder = Color(0xFFC9D3C2);
  static const disabled = Color(0xFF7D8A80);
  // Neutros oscuro
  static const bgDark = Color(0xFF13201A);
  static const cardDark = Color(0xFF1C2C24);
  static const borderDark = Color(0xFF2C4036);
  static const trackDark = Color(0xFF24362C);
  static const textDark = Color(0xFFEEF3EC);
  static const text2Dark = Color(0xFFA9B8AD);
  static const inputBorderDark = Color(0xFF3A5446);
  // Semánticos
  static const coral = Color(0xFFE0573F);
  static const coralInk = Color(0xFFA8361F);
  static const coralTint = Color(0xFFFBE4DF);
  static const mustard = Color(0xFFD9A21B);
  static const mustardInk = Color(0xFF6E4D00);
  static const mustardTint = Color(0xFFFBF0D3);
  static const river = Color(0xFF3C5BA8);
  static const riverInk = Color(0xFF2C4580);
  static const riverTint = Color(0xFFE3E9F7);
  static const boss = Color(0xFF2A2020);
  static const focus = Color(0xFF3C5BA8);
}

class QRealm {
  final Color accent, onAccent, ink, inkDark, tint, tintDark, heroBg, heroHill;
  const QRealm({required this.accent, required this.onAccent, required this.ink, required this.inkDark,
      required this.tint, required this.tintDark, required this.heroBg, required this.heroHill});

  static const bosque = QRealm(accent: Color(0xFF2E7D4F), onAccent: Colors.white, ink: Color(0xFF1F5C39), inkDark: Color(0xFF9FDCB4),
      tint: Color(0xFFE1F0E6), tintDark: Color(0xFF1F3A2C), heroBg: Color(0xFF1F5C39), heroHill: Color(0xFF2E7D4F));
  static const rio = QRealm(accent: Color(0xFF3C5BA8), onAccent: Colors.white, ink: Color(0xFF2C4580), inkDark: Color(0xFFB9CBF0),
      tint: Color(0xFFE3E9F7), tintDark: Color(0xFF1E2A44), heroBg: Color(0xFF24396B), heroHill: Color(0xFF3C5BA8));
  static const brasa = QRealm(accent: Color(0xFFA8361F), onAccent: Colors.white, ink: Color(0xFF8A2C19), inkDark: Color(0xFFF5B8A8),
      tint: Color(0xFFFBE4DF), tintDark: Color(0xFF3A1F1A), heroBg: Color(0xFF7A2716), heroHill: Color(0xFFA8361F));
  static const oro = QRealm(accent: Color(0xFFD9A21B), onAccent: Color(0xFF3D2B00), ink: Color(0xFF6E4D00), inkDark: Color(0xFFF5D896),
      tint: Color(0xFFFBF0D3), tintDark: Color(0xFF3A3016), heroBg: Color(0xFF5C4100), heroHill: Color(0xFF8A6200));
  static const night = (bg: Color(0xFF0E1B14), hill: Color(0xFF1C2C24));

  static QRealm of(QuestlyRealm r) => switch (r) {
        QuestlyRealm.bosque => bosque,
        QuestlyRealm.rio => rio,
        QuestlyRealm.brasa => brasa,
        QuestlyRealm.oro => oro,
      };
}

class QSpace { static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, gutter = 20.0, xl = 24.0, xxl = 32.0; }
class QRadius { static const chip = 6.0, control = 12.0, button = 14.0, block = 16.0, card = 20.0, sheet = 24.0, hero = 26.0, pill = 99.0; }
class QSize { static const minTap = 44.0, buttonPrimary = 52.0, hero = 156.0; }

class QMotion {
  static const press = Duration(milliseconds: 80);
  static const fade = Duration(milliseconds: 250);
  static const sheet = Duration(milliseconds: 300);
  static const pop = Duration(milliseconds: 450);
  static const shake = Duration(milliseconds: 500);
  static const float = Duration(milliseconds: 1300);
  static const bob = Duration(milliseconds: 2600);
}

/// Sombra «de juego»: sólida de 4 px bajo la tarjeta o el botón.
List<BoxShadow> qSolidShadow(Color c, {double y = 4}) => [BoxShadow(color: c, offset: Offset(0, y), blurRadius: 0)];

class QText {
  static TextStyle display(Color c) => GoogleFonts.bricolageGrotesque(fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, color: c);
  static TextStyle title1(Color c) => GoogleFonts.bricolageGrotesque(fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, color: c);
  static TextStyle title2(Color c) => GoogleFonts.bricolageGrotesque(fontSize: 22, height: 1.2, fontWeight: FontWeight.w800, color: c);
  static TextStyle title3(Color c) => GoogleFonts.bricolageGrotesque(fontSize: 18, height: 1.25, fontWeight: FontWeight.w800, color: c);
  static TextStyle body(Color c) => GoogleFonts.dmSans(fontSize: 15, height: 1.45, color: c);
  static TextStyle label(Color c) => GoogleFonts.dmSans(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700, color: c);
  static TextStyle meta(Color c) => GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.96, color: c);
  static TextStyle number(Color c, {double size = 15}) => GoogleFonts.dmMono(fontSize: size, fontWeight: FontWeight.w500, color: c);
}

ThemeData questlyTheme({required QuestlyRealm realm, required bool dark}) {
  final r = QRealm.of(realm);
  final bg = dark ? QColors.bgDark : QColors.bg;
  final card = dark ? QColors.cardDark : QColors.card;
  final text = dark ? QColors.textDark : QColors.text;
  final text2 = dark ? QColors.text2Dark : QColors.text2;
  final ink = dark ? r.inkDark : r.ink;
  final tint = dark ? r.tintDark : r.tint;
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: r.accent, onPrimary: r.onAccent,
      secondary: ink, onSecondary: card,
      primaryContainer: tint, onPrimaryContainer: ink,
      error: dark ? const Color(0xFFF5B8A8) : QColors.coralInk, onError: Colors.white,
      surface: card, onSurface: text, onSurfaceVariant: text2,
      outline: dark ? QColors.borderDark : QColors.border,
    ),
    textTheme: TextTheme(
      displaySmall: QText.display(text), headlineMedium: QText.title1(text), titleLarge: QText.title2(text),
      titleMedium: QText.title3(text), bodyLarge: QText.body(text), bodyMedium: QText.body(text2),
      labelLarge: QText.label(text), labelSmall: QText.meta(text2),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: r.accent, foregroundColor: r.onAccent, disabledBackgroundColor: QColors.disabled,
      minimumSize: const Size.fromHeight(QSize.buttonPrimary), textStyle: QText.label(r.onAccent).copyWith(fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QRadius.button)),
    )),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: card,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(QRadius.button), borderSide: BorderSide(color: dark ? QColors.inputBorderDark : QColors.inputBorder, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(QRadius.button), borderSide: const BorderSide(color: QColors.focus, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(QRadius.button), borderSide: const BorderSide(color: QColors.coralInk, width: 1.5)),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
