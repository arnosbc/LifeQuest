import 'package:equatable/equatable.dart';

/// Paso pendiente de una tarea guiada, para hacerlo sin salir de Foco (068).
class DungeonStep extends Equatable {
  const DungeonStep({
    required this.id,
    required this.title,
    required this.position,
    this.minutes,
  });

  final String id;
  final String title;
  final int position;

  /// Estimación de Nevi; null si no la hay.
  final int? minutes;

  @override
  List<Object?> get props => [id, title, position, minutes];
}

/// Lo que se hace en una sesión de Foco: una tarea o un hábito de hoy (068).
class DungeonTask extends Equatable {
  const DungeonTask({
    required this.id,
    required this.title,
    this.done = false,
    this.cycles = 0,
    this.isHabit = false,
    this.minutes,
    this.stepCount = 0,
    this.step,
  });

  final String id;
  final String title;
  final bool done;

  /// Ciclos cobrados con esta tarea (o hábito) en la sesión.
  final int cycles;
  final bool isHabit;

  /// Minutos que Nevi estima para lo que falta; null si no hay estimación.
  final int? minutes;
  final int stepCount;

  /// Paso que toca ahora; null sin pasos pendientes.
  final DungeonStep? step;

  /// Tiempo que propone Foco: la estimación o, sin ella, un bloque.
  int minutesOr(int cycleMinutes) => minutes ?? cycleMinutes;

  @override
  List<Object?> get props => [
    id,
    title,
    done,
    cycles,
    isHabit,
    minutes,
    stepCount,
    step,
  ];
}

/// Sesión de Deep Working abierta.
class DungeonSession extends Equatable {
  const DungeonSession({
    required this.id,
    required this.totalMinutes,
    required this.cycleMinutes,
    required this.tasks,
    this.habits = const [],
    this.cyclesDone = 0,
    this.xpEarned = 0,
    this.coinsEarned = 0,
    this.missionsDone = 0,
  });

  final String id;
  final int totalMinutes;
  final int cycleMinutes;
  final List<DungeonTask> tasks;

  /// Hábitos de hoy dentro de la sesión ([DungeonTask.isHabit]).
  final List<DungeonTask> habits;
  final int cyclesDone;

  /// Tareas y hábitos, en el orden en que se muestran.
  List<DungeonTask> get items => [...tasks, ...habits];

  /// Lo ganado en la sesión: ciclos y misiones de la mochila (033).
  final int xpEarned;
  final int coinsEarned;

  /// Misiones de la mochila completadas durante la sesión.
  final int missionsDone;

  /// Ciclos que caben en la sesión; el servidor no paga más.
  int get maxCycles => totalMinutes ~/ cycleMinutes;

  /// Tiempo efectivo: solo los ciclos de concentración cobrados, sin
  /// descansos ni pausas (igual que `end_dungeon`, 033).
  int get focusMinutes => cyclesDone * cycleMinutes;

  @override
  List<Object?> get props => [
    id,
    totalMinutes,
    cycleMinutes,
    tasks,
    habits,
    cyclesDone,
    xpEarned,
    coinsEarned,
    missionsDone,
  ];
}

/// Lo que pagó el servidor al completar una misión.
class DungeonReward extends Equatable {
  const DungeonReward({this.xp = 0, this.coins = 0});

  final int xp;

  /// Monedas a la bolsa más las que pasaron al Tesoro.
  final int coins;

  @override
  List<Object?> get props => [xp, coins];
}

/// Todo lo que muestra la pantalla Mazmorra, en una sola carga.
class DungeonBoard extends Equatable {
  const DungeonBoard({
    this.session,
    this.candidates = const [],
    this.habitCandidates = const [],
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

  /// Hábitos buenos de hoy aún sin cumplir; cuentan en el tope [maxTasks].
  final List<DungeonTask> habitCandidates;
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
    habitCandidates,
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
    this.missions = 0,
  });

  final int cycles;

  /// Botín completo: ciclos y misiones de la mochila (033).
  final int xp;
  final int coins;

  /// Tiempo efectivo: ciclos cobrados × duración del ciclo.
  final int minutes;

  /// Misiones de la mochila completadas en la sesión.
  final int missions;

  @override
  List<Object?> get props => [cycles, xp, coins, minutes, missions];
}
