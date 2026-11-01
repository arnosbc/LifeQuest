// Tokens del sistema visual minimal (docs/diseño/DESIGN.md): neutros zinc,
// un acento índigo, bordes finos y tipografía Inter (assets/fonts).

import 'package:flutter/material.dart';

abstract final class QColors {
  // Neutros claro
  static const bg = Color(0xFFFAFAFA);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E4E7);
  static const track = Color(0xFFF4F4F5);
  static const line = Color(0xFFF4F4F5);
  static const text = Color(0xFF18181B);
  static const text2 = Color(0xFF52525B);
  static const text3 = Color(0xFF3F3F46);
  static const inputBorder = Color(0xFFD4D4D8);
  static const disabled = Color(0xFF71717A);
  // Neutros oscuro
  static const bgDark = Color(0xFF09090B);
  static const cardDark = Color(0xFF18181B);
  static const borderDark = Color(0xFF27272A);
  static const trackDark = Color(0xFF27272A);
  static const textDark = Color(0xFFFAFAFA);
  static const text2Dark = Color(0xFFA1A1AA);
  static const inputBorderDark = Color(0xFF3F3F46);
  // Acento
  static const accent = Color(0xFF4F46E5);
  static const accentInk = Color(0xFF3730A3);
  static const accentInkDark = Color(0xFFA5B4FC);
  static const accentTint = Color(0xFFEEF2FF);
  static const accentTintDark = Color(0xFF1E1B4B);
  // Semánticos: rojo (error, mal hábito), ámbar (aviso, racha), azul (info).
  static const coral = Color(0xFFDC2626);
  static const coralInk = Color(0xFFB91C1C);
  static const coralTint = Color(0xFFFEF2F2);
  static const mustard = Color(0xFFD97706);
  static const mustardInk = Color(0xFF92400E);
  static const mustardTint = Color(0xFFFFFBEB);
  static const river = Color(0xFF2563EB);
  static const riverInk = Color(0xFF1D4ED8);
  static const riverTint = Color(0xFFEFF6FF);
  static const focus = accent;
}

abstract final class QSpace {
  static const xs = 4.0,
      s = 8.0,
      m = 12.0,
      l = 16.0,
      gutter = 20.0,
      xl = 24.0,
      xxl = 32.0;
}

abstract final class QRadius {
  static const chip = 6.0,
      control = 8.0,
      button = 10.0,
      block = 12.0,
      card = 14.0,
      sheet = 20.0,
      pill = 99.0;
}

abstract final class QSize {
  static const minTap = 44.0, buttonPrimary = 48.0;
}

abstract final class QMotion {
  static const press = Duration(milliseconds: 80);
  static const fade = Duration(milliseconds: 200);
  static const sheet = Duration(milliseconds: 250);
}

abstract final class QText {
  static const family = 'Inter';

  static TextStyle _inter(
    Color c,
    double size, {
    double? height,
    FontWeight weight = FontWeight.w400,
    double? spacing,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: spacing,
    color: c,
  );

  static TextStyle display(Color c) =>
      _inter(c, 32, height: 1.15, weight: FontWeight.w700, spacing: -0.8);
  static TextStyle title1(Color c) =>
      _inter(c, 26, height: 1.2, weight: FontWeight.w700, spacing: -0.6);
  static TextStyle title2(Color c) =>
      _inter(c, 20, height: 1.25, weight: FontWeight.w600, spacing: -0.3);
  static TextStyle title3(Color c) =>
      _inter(c, 17, height: 1.3, weight: FontWeight.w600, spacing: -0.2);
  static TextStyle body(Color c) => _inter(c, 15, height: 1.45);
  static TextStyle label(Color c) =>
      _inter(c, 14, height: 1.3, weight: FontWeight.w500);
  static TextStyle meta(Color c) =>
      _inter(c, 12, weight: FontWeight.w500, spacing: 0.2);
  static TextStyle number(Color c, {double size = 15}) => _inter(
    c,
    size,
    weight: FontWeight.w600,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData questlyTheme({required bool dark}) {
  final bg = dark ? QColors.bgDark : QColors.bg;
  final card = dark ? QColors.cardDark : QColors.card;
  final text = dark ? QColors.textDark : QColors.text;
  final text2 = dark ? QColors.text2Dark : QColors.text2;
  final border = dark ? QColors.borderDark : QColors.border;
  final ink = dark ? QColors.accentInkDark : QColors.accentInk;
  final tint = dark ? QColors.accentTintDark : QColors.accentTint;
  final inputBorder = dark ? QColors.inputBorderDark : QColors.inputBorder;
  OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(QRadius.button),
    borderSide: BorderSide(color: c, width: w),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: QText.family,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: QColors.accent,
      onPrimary: Colors.white,
      secondary: ink,
      onSecondary: card,
      primaryContainer: tint,
      onPrimaryContainer: ink,
      error: dark ? const Color(0xFFFCA5A5) : QColors.coralInk,
      onError: Colors.white,
      surface: card,
      onSurface: text,
      onSurfaceVariant: text2,
      outline: border,
    ),
    textTheme: TextTheme(
      displaySmall: QText.display(text),
      headlineMedium: QText.title1(text),
      titleLarge: QText.title2(text),
      titleMedium: QText.title3(text),
      bodyLarge: QText.body(text),
      bodyMedium: QText.body(text2),
      labelLarge: QText.label(text),
      labelSmall: QText.meta(text2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: text,
      titleTextStyle: QText.title3(text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: QColors.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: QColors.disabled,
        minimumSize: const Size.fromHeight(QSize.buttonPrimary),
        textStyle: QText.label(Colors.white).copyWith(fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        minimumSize: const Size(QSize.minTap, QSize.minTap),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.button),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QRadius.card),
        side: BorderSide(color: border),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      enabledBorder: outline(inputBorder),
      border: outline(inputBorder),
      focusedBorder: outline(QColors.focus, 1.5),
      errorBorder: outline(QColors.coralInk),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
