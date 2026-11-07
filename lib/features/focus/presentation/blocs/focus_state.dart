part of 'focus_bloc.dart';

/// setup: sin sesión (elegir mochila) · focus: ciclo en curso ·
/// rest: descanso · done: no caben más ciclos, solo queda terminar.
enum FocusPhase { setup, focus, rest, done }

sealed class FocusState extends Equatable {
  const FocusState();

  @override
  List<Object?> get props => [];
}

class FocusInitial extends FocusState {
  const FocusInitial();
}

class FocusLoading extends FocusState {
  const FocusLoading();
}

/// La primera carga falló; no hay datos que mostrar.
class FocusFailure extends FocusState {
  const FocusFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// XP recién ganada, para la animación «+N XP». [seq] cambia con cada
/// ganancia, así la pantalla sabe que es nueva.
class FocusGain extends Equatable {
  const FocusGain({required this.xp, required this.levelUp, required this.seq});

  final int xp;
  final bool levelUp;
  final int seq;

  @override
  List<Object?> get props => [xp, levelUp, seq];
}

class FocusReady extends FocusState {
  const FocusReady({
    required this.board,
    required this.phase,
    required this.now,
    this.phaseEndsAt,
    this.pausedLeft,
    this.currentTaskId,
    this.busy = false,
    this.message,
    this.summary,
    this.intention,
    this.gain,
    this.nextScheduledAt,
  });

  final FocusBoard board;
  final FocusPhase phase;

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
  final FocusSummary? summary;

  /// Meta del ciclo que escribió el usuario.
  // shortcut: vive en memoria; se pierde si se cierra la app a mitad de sesión.
  final String? intention;

  /// Última XP ganada en la sesión (se conserva para animarla una vez).
  final FocusGain? gain;

  /// Hora a la que se agendó lo que sigue, desde el resumen.
  final DateTime? nextScheduledAt;

  bool get paused => pausedLeft != null;

  Duration get remaining {
    if (pausedLeft case final left?) return left;
    final end = phaseEndsAt;
    if (end == null || !end.isAfter(now)) return Duration.zero;
    return end.difference(now);
  }

  /// Copia; [message], [summary] y [nextScheduledAt] se limpian salvo que
  /// se pasen.
  FocusReady copyWith({
    FocusBoard? board,
    FocusPhase? phase,
    DateTime? now,
    DateTime? Function()? phaseEndsAt,
    Duration? Function()? pausedLeft,
    String? Function()? currentTaskId,
    bool? busy,
    String? message,
    FocusSummary? summary,
    String? Function()? intention,
    FocusGain? gain,
    DateTime? nextScheduledAt,
  }) => FocusReady(
    board: board ?? this.board,
    phase: phase ?? this.phase,
    now: now ?? this.now,
    phaseEndsAt: phaseEndsAt == null ? this.phaseEndsAt : phaseEndsAt(),
    pausedLeft: pausedLeft == null ? this.pausedLeft : pausedLeft(),
    currentTaskId: currentTaskId == null ? this.currentTaskId : currentTaskId(),
    busy: busy ?? this.busy,
    message: message,
    summary: summary,
    intention: intention == null ? this.intention : intention(),
    gain: gain ?? this.gain,
    nextScheduledAt: nextScheduledAt,
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
    intention,
    gain,
    nextScheduledAt,
  ];
}
