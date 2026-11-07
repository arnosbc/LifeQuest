/// Indicaciones breves para cada descanso de Foco. Reglas fijas, sin IA.
abstract final class FocusGuide {
  static const _short = [
    'Levántate y estira la espalda y los hombros.',
    'Toma un vaso de agua.',
    'Mira algo lejano por la ventana: descansa la vista.',
    'Respira hondo tres veces, despacio.',
  ];

  static const _long = [
    'Camina unos minutos, lejos de la pantalla.',
    'Come algo ligero y toma agua.',
  ];

  /// Indicación del descanso que sigue a [cyclesDone] ciclos; [long] si es
  /// el descanso largo. Rota para no repetir la misma cada vez.
  static String breakTip(int cyclesDone, {required bool long}) {
    final tips = long ? _long : _short;
    return tips[(cyclesDone > 0 ? cyclesDone - 1 : 0) % tips.length];
  }
}
