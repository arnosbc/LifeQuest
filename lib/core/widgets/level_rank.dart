/// Rango que acompaña al nivel (plan §3.1: Inicial · En marcha · Constante ·
/// Avanzado · Experto). Solo es un rótulo de la UI: no cambia ninguna regla.
/// shortcut: tramos fijos; pasar a `game_rules` si se quieren ajustar sin publicar.
String levelRank(int level) => switch (level) {
  <= 2 => 'Inicial',
  <= 5 => 'En marcha',
  <= 9 => 'Constante',
  <= 14 => 'Avanzado',
  _ => 'Experto',
};
