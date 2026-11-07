part of 'focus_bloc.dart';

sealed class FocusEvent extends Equatable {
  const FocusEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar Foco.
class FocusRequested extends FocusEvent {
  const FocusRequested();
}

/// Entrar con la duración, el ciclo y la mochila elegidos.
class FocusStarted extends FocusEvent {
  const FocusStarted({
    required this.totalMinutes,
    required this.cycleMinutes,
    required this.taskIds,
    this.intention,
  });

  final int totalMinutes;
  final int cycleMinutes;
  final List<String> taskIds;

  /// «¿Qué vas a terminar en este ciclo?» (opcional).
  final String? intention;

  @override
  List<Object?> get props => [totalMinutes, cycleMinutes, taskIds, intention];
}

/// Cambiar la meta del próximo ciclo (p. ej. durante el descanso).
class FocusIntentionChanged extends FocusEvent {
  const FocusIntentionChanged(this.intention);

  final String intention;

  @override
  List<Object?> get props => [intention];
}

/// Marcar un paso de la tarea en foco.
class FocusStepCompleted extends FocusEvent {
  const FocusStepCompleted(this.stepId);

  final String stepId;

  @override
  List<Object?> get props => [stepId];
}

/// Añadir un paso a una tarea de la sesión.
class FocusStepAdded extends FocusEvent {
  const FocusStepAdded({required this.taskId, required this.title});

  final String taskId;
  final String title;

  @override
  List<Object?> get props => [taskId, title];
}

/// «Empezar foco» desde una tarea: arranca ya, sin preparar la sesión.
class FocusQuickStarted extends FocusEvent {
  const FocusQuickStarted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Pasos propuestos por el asistente, añadidos de una vez.
class FocusStepsAdded extends FocusEvent {
  const FocusStepsAdded({required this.taskId, required this.titles});

  final String taskId;
  final List<String> titles;

  @override
  List<Object?> get props => [taskId, titles];
}

/// Agendar lo que quedó pendiente (desde el resumen).
class FocusNextScheduled extends FocusEvent {
  const FocusNextScheduled({required this.taskId, required this.at});

  final String taskId;
  final DateTime at;

  @override
  List<Object?> get props => [taskId, at];
}

/// Pasó un segundo (lo envía el propio bloc).
class FocusTicked extends FocusEvent {
  const FocusTicked();
}

class FocusPauseToggled extends FocusEvent {
  const FocusPauseToggled();
}

class FocusBreakSkipped extends FocusEvent {
  const FocusBreakSkipped();
}

/// La tarea en la que se concentra el ciclo actual.
class FocusTaskSelected extends FocusEvent {
  const FocusTaskSelected(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class FocusTaskCompleted extends FocusEvent {
  const FocusTaskCompleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Terminar la sesión antes o después de agotar los ciclos.
class FocusEnded extends FocusEvent {
  const FocusEnded();
}

/// Cerrar el resumen de la sesión terminada.
class FocusSummaryDismissed extends FocusEvent {
  const FocusSummaryDismissed();
}
