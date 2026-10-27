import 'package:equatable/equatable.dart';

/// Misión dentro de la mochila de la Mazmorra (o candidata a entrar).
class DungeonTask extends Equatable {
  const DungeonTask({
    required this.id,
    required this.title,
    this.done = false,
    this.cycles = 0,
  });

  final String id;
  final String title;
  final bool done;

  /// Ciclos cobrados con esta tarea en la sesión.
  final int cycles;

  @override
  List<Object?> get props => [id, title, done, cycles];
}

/// Sesión de Deep Working abierta.
class DungeonSession extends Equatable {
  const DungeonSession({
    required this.id,
    required this.totalMinutes,
    required this.cycleMinutes,
    required this.tasks,
    this.cyclesDone = 0,
    this.xpEarned = 0,
    this.coinsEarned = 0,
  });

  final String id;
  final int totalMinutes;
  final int cycleMinutes;
  final List<DungeonTask> tasks;
  final int cyclesDone;
  final int xpEarned;
  final int coinsEarned;

  /// Ciclos que caben en la sesión; el servidor no paga más.
  int get maxCycles => totalMinutes ~/ cycleMinutes;

  @override
  List<Object?> get props => [
    id,
    totalMinutes,
    cycleMinutes,
    tasks,
    cyclesDone,
    xpEarned,
    coinsEarned,
  ];
}

/// Todo lo que muestra la pantalla Mazmorra, en una sola carga.
class DungeonBoard extends Equatable {
  const DungeonBoard({
    this.session,
    this.candidates = const [],
    this.maxTasks = 5,
    this.cycleXp = 10,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakEveryNCycles = 4,
  });

  /// Null si no hay sesión abierta.
  final DungeonSession? session;

  /// Misiones abiertas para llenar la mochila.
  final List<DungeonTask> candidates;
  final int maxTasks;

  /// XP base por ciclo (sin multiplicadores).
  final int cycleXp;

  /// RF-067: descansos que el jugador eligió en Configuración.
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakEveryNCycles;

  /// Descanso que sigue a [cyclesDone] ciclos superados.
  Duration breakAfter(int cyclesDone) => Duration(
    minutes: cyclesDone > 0 && cyclesDone % longBreakEveryNCycles == 0
        ? longBreakMinutes
        : shortBreakMinutes,
  );

  @override
  List<Object?> get props => [
    session,
    candidates,
    maxTasks,
    cycleXp,
    shortBreakMinutes,
    longBreakMinutes,
    longBreakEveryNCycles,
  ];
}

/// Resumen al cerrar la sesión.
class DungeonSummary extends Equatable {
  const DungeonSummary({
    required this.cycles,
    required this.xp,
    required this.coins,
    required this.minutes,
  });

  final int cycles;
  final int xp;
  final int coins;
  final int minutes;

  @override
  List<Object?> get props => [cycles, xp, coins, minutes];
}
