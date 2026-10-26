part of 'dungeon_bloc.dart';

/// setup: sin sesión (elegir mochila) · focus: ciclo en curso ·
/// rest: descanso · done: no caben más ciclos, solo queda terminar.
enum DungeonPhase { setup, focus, rest, done }

sealed class DungeonState extends Equatable {
  const DungeonState();

  @override
  List<Object?> get props => [];
}

class DungeonInitial extends DungeonState {
  const DungeonInitial();
}

class DungeonLoading extends DungeonState {
  const DungeonLoading();
}

/// La primera carga falló; no hay datos que mostrar.
class DungeonFailure extends DungeonState {
  const DungeonFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DungeonReady extends DungeonState {
  const DungeonReady({
    required this.board,
    required this.phase,
    required this.now,
    this.phaseEndsAt,
    this.pausedLeft,
    this.currentTaskId,
    this.busy = false,
    this.message,
    this.summary,
  });

  final DungeonBoard board;
  final DungeonPhase phase;

  /// Hora del último tic; la pantalla calcula el tiempo restante con ella.
  final DateTime now;

  /// Fin del ciclo o del descanso en curso (null en pausa, setup o done).
  final DateTime? phaseEndsAt;

  /// Tiempo que quedaba al pausar.
  final Duration? pausedLeft;
  final String? currentTaskId;
  final bool busy;

  /// Aviso puntual para un snackbar.
  final String? message;

  /// Resumen de la sesión recién terminada (fase setup).
  final DungeonSummary? summary;

  bool get paused => pausedLeft != null;

  Duration get remaining {
    if (pausedLeft case final left?) return left;
    final end = phaseEndsAt;
    if (end == null || !end.isAfter(now)) return Duration.zero;
    return end.difference(now);
  }

  /// Copia; [message] y [summary] se limpian salvo que se pasen.
  DungeonReady copyWith({
    DungeonBoard? board,
    DungeonPhase? phase,
    DateTime? now,
    DateTime? Function()? phaseEndsAt,
    Duration? Function()? pausedLeft,
    String? Function()? currentTaskId,
    bool? busy,
    String? message,
    DungeonSummary? summary,
  }) => DungeonReady(
    board: board ?? this.board,
    phase: phase ?? this.phase,
    now: now ?? this.now,
    phaseEndsAt: phaseEndsAt == null ? this.phaseEndsAt : phaseEndsAt(),
    pausedLeft: pausedLeft == null ? this.pausedLeft : pausedLeft(),
    currentTaskId: currentTaskId == null ? this.currentTaskId : currentTaskId(),
    busy: busy ?? this.busy,
    message: message,
    summary: summary,
  );

  @override
  List<Object?> get props => [
    board,
    phase,
    now,
    phaseEndsAt,
    pausedLeft,
    currentTaskId,
    busy,
    message,
    summary,
  ];
}
