// Tokens del mundo «calendario de taco» (docs/diseño/DESIGN.md): suelo de
// papel, hoja blanca, tinta, un rojo solo para marcas y Archivo (assets/fonts).

import 'package:flutter/material.dart';

abstract final class QColors {
  // Papel claro: suelo gris cálido y hoja blanca.
  static const bg = Color(0xFFF1EFEA);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E1DA);
  static const track = Color(0xFFECE9E3);
  static const line = Color(0xFFE4E1DA);
  static const text = Color(0xFF111111);
  static const text2 = Color(0xFF6B6862);
  static const text3 = Color(0xFF3A3834);
  static const inputBorder = Color(0xFFD3CFC6);
  static const disabled = Color(0xFF6B6862);
  // Papel oscuro.
  static const bgDark = Color(0xFF141312);
  static const cardDark = Color(0xFF1E1D1B);
  static const borderDark = Color(0xFF2E2C29);
  static const trackDark = Color(0xFF2A2826);
  static const textDark = Color(0xFFF2F0EB);
  static const text2Dark = Color(0xFFA6A29A);
  static const inputBorderDark = Color(0xFF44413C);
  // Las acciones van en tinta; el rojo solo marca la fecha, lo actual y «ahora».
  static const mark = Color(0xFFD7262E);
  static const markDark = Color(0xFFFF6B70);
  // Semánticos: rojo (error, mal hábito), ámbar (racha), azul (info).
  static const coral = Color(0xFFD7262E);
  static const coralInk = Color(0xFFB3261E);
  static const coralTint = Color(0xFFFBE9EA);
  static const mustard = Color(0xFFC77700);
  static const mustardInk = Color(0xFF8A4B00);
  static const mustardTint = Color(0xFFFBF1DE);
  static const river = Color(0xFF2B59C3);
  static const riverInk = Color(0xFF1F449A);
  static const riverTint = Color(0xFFE8EEFA);
  static const focus = Color(0xFF2B59C3);
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
      button = 24.0,
      block = 10.0,
      card = 12.0,
      sheet = 20.0,
      pill = 99.0;
}

abstract final class QSize {
  static const minTap = 44.0, buttonPrimary = 48.0;
}

abstract final class QMotion {
  static const press = Duration(milliseconds: 160);
  static const fade = Duration(milliseconds: 200);
  static const sheet = Duration(milliseconds: 250);

  /// Ease-out fuerte: el toque responde al instante.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Para lo que se mueve dentro de la pantalla.
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// Curva de cajón tipo iOS para las hojas inferiores.
  static const drawer = Cubic(0.32, 0.72, 0, 1);
}

abstract final class QText {
  static const family = 'Archivo';

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

  /// El número de la hoja: uno por pantalla, nunca más.
  static TextStyle numeral(Color c, {double size = 168}) => _inter(
    c,
    size,
    height: 0.86,
    weight: FontWeight.w900,
    spacing: -size * 0.04,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle display(Color c) =>
      _inter(c, 32, height: 1.1, weight: FontWeight.w800, spacing: -1);
  static TextStyle title1(Color c) =>
      _inter(c, 28, height: 1.15, weight: FontWeight.w800, spacing: -0.8);
  static TextStyle title2(Color c) =>
      _inter(c, 20, height: 1.25, weight: FontWeight.w700, spacing: -0.3);
  static TextStyle title3(Color c) =>
      _inter(c, 17, height: 1.3, weight: FontWeight.w600, spacing: -0.2);
  static TextStyle body(Color c) => _inter(c, 15, height: 1.45);
  static TextStyle label(Color c) =>
      _inter(c, 15, height: 1.3, weight: FontWeight.w600);
  static TextStyle meta(Color c) =>
      _inter(c, 12, weight: FontWeight.w600, spacing: 0.3);
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
  final ink = text;
  final tint = dark ? QColors.trackDark : QColors.track;
  final mark = dark ? QColors.markDark : QColors.mark;
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
      primary: text,
      onPrimary: card,
      secondary: ink,
      onSecondary: card,
      primaryContainer: tint,
      onPrimaryContainer: ink,
      error: dark ? QColors.markDark : QColors.coralInk,
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
        backgroundColor: text,
        foregroundColor: card,
        disabledBackgroundColor: border,
        disabledForegroundColor: text2,
        minimumSize: const Size.fromHeight(QSize.buttonPrimary),
        textStyle: QText.label(card),
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
      focusedBorder: outline(text, 1.5),
      errorBorder: outline(QColors.coralInk),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: text,
      foregroundColor: card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: text,
      linearTrackColor: tint,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: mark,
      selectionColor: mark.withValues(alpha: 0.25),
      selectionHandleColor: mark,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: text,
      contentTextStyle: QText.body(card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QRadius.block),
      ),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
