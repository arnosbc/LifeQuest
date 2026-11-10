import 'package:equatable/equatable.dart';

/// Paso (subtarea) de una tarea de la sesión; se marca con complete_task.
class FocusStep extends Equatable {
  const FocusStep({
    required this.id,
    required this.title,
    this.done = false,
    this.proof,
    this.proofPhoto = false,
  });

  final String id;
  final String title;
  final bool done;

  /// Prueba del paso (045): lo que el usuario escribió que hizo.
  final String? proof;

  /// Hay una foto como prueba.
  final bool proofPhoto;

  @override
  List<Object?> get props => [id, title, done, proof, proofPhoto];
}

/// Tarea dentro de la mochila de Foco (o candidata a entrar).
class FocusTask extends Equatable {
  const FocusTask({
    required this.id,
    required this.title,
    this.done = false,
    this.cycles = 0,
    this.steps = const [],
    this.resumeNote,
    this.resources = 0,
  });

  final String id;
  final String title;
  final bool done;

  /// «Dónde lo dejé» de la última sesión (045).
  final String? resumeNote;

  /// Recursos adjuntos a la tarea.
  final int resources;

  /// Ciclos cobrados con esta tarea en la sesión.
  final int cycles;
  final List<FocusStep> steps;

  int get stepsDone => steps.where((s) => s.done).length;

  /// Primer paso sin hacer: lo que toca ahora dentro de la tarea.
  FocusStep? get nextStep => steps.where((s) => !s.done).firstOrNull;

  /// Lo que el usuario dejó escrito la última vez: su nota de retomar y las
  /// pruebas de los pasos hechos (máx. 4). Es el material del repaso.
  List<String> get recallNotes => [
    ?resumeNote,
    for (final s in steps)
      if (s.done && s.proof != null) '${s.title}: ${s.proof}',
  ].take(4).toList();

  /// Propuesta para «Dónde lo dejé»: el usuario la edita.
  String get resumeSuggestion =>
      nextStep == null ? '' : 'Sigue: ${nextStep!.title}';

  @override
  List<Object?> get props => [
    id,
    title,
    done,
    cycles,
    steps,
    resumeNote,
    resources,
  ];
}

/// Nivel y XP del personaje, para la barra en vivo.
class FocusProgress extends Equatable {
  const FocusProgress({
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
  });

  final int level;
  final int currentXp;
  final int xpToNextLevel;

  double get fraction =>
      xpToNextLevel <= 0 ? 0 : (currentXp / xpToNextLevel).clamp(0, 1);

  /// XP ganada desde [before]. Si subió de nivel, cuenta lo que faltaba
  /// para subir más lo nuevo (basta para una subida por acción).
  int gainSince(FocusProgress before) => level > before.level
      ? before.xpToNextLevel - before.currentXp + currentXp
      : currentXp - before.currentXp;

  @override
  List<Object?> get props => [level, currentXp, xpToNextLevel];
}

/// Sesión de Deep Working abierta.
class FocusSession extends Equatable {
  const FocusSession({
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
  final List<FocusTask> tasks;
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

/// Todo lo que muestra la pantalla Foco, en una sola carga.
class FocusBoard extends Equatable {
  const FocusBoard({
    this.session,
    this.candidates = const [],
    this.maxTasks = 5,
    this.cycleXp = 10,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakEveryNCycles = 4,
    this.progress,
    this.weekMinutes = 0,
    this.prevWeekMinutes = 0,
  });

  /// Null si no hay sesión abierta.
  final FocusSession? session;

  /// Tareas abiertas para llenar la mochila.
  final List<FocusTask> candidates;
  final int maxTasks;

  /// XP base por ciclo (sin multiplicadores).
  final int cycleXp;

  /// RF-067: descansos que el jugador eligió en Ajustes.
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakEveryNCycles;

  /// Null si aún no hay fila de estadísticas.
  final FocusProgress? progress;

  /// Minutos de foco de los últimos 7 días y de los 7 anteriores.
  final int weekMinutes;
  final int prevWeekMinutes;

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
    progress,
    weekMinutes,
    prevWeekMinutes,
  ];
}

/// Resumen al cerrar la sesión: lo que pagó el servidor y la historia
/// (qué se terminó, cómo va la semana y qué sigue).
class FocusSummary extends Equatable {
  const FocusSummary({
    required this.cycles,
    required this.xp,
    required this.coins,
    required this.minutes,
    this.tasks = const [],
    this.weekMinutes = 0,
    this.prevWeekMinutes = 0,
    this.distractions = 0,
  });

  /// Ideas que se mandaron a la Bandeja durante la sesión.
  final int distractions;

  final int cycles;
  final int xp;
  final int coins;
  final int minutes;

  /// Tareas de la sesión como quedaron al cerrarla.
  final List<FocusTask> tasks;
  final int weekMinutes;
  final int prevWeekMinutes;

  /// Primera tarea sin terminar: lo que conviene agendar para mañana.
  FocusTask? get next => tasks.where((t) => !t.done).firstOrNull;

  FocusSummary withStory({
    required List<FocusTask> tasks,
    required int weekMinutes,
    required int prevWeekMinutes,
    int distractions = 0,
  }) => FocusSummary(
    distractions: distractions,
    cycles: cycles,
    xp: xp,
    coins: coins,
    minutes: minutes,
    tasks: tasks,
    weekMinutes: weekMinutes,
    prevWeekMinutes: prevWeekMinutes,
  );

  @override
  List<Object?> get props => [
    cycles,
    xp,
    coins,
    minutes,
    tasks,
    weekMinutes,
    prevWeekMinutes,
    distractions,
  ];
}
