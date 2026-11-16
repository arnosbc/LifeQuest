part of 'dungeon_bloc.dart';

sealed class DungeonEvent extends Equatable {
  const DungeonEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar la Mazmorra. Con [taskId] («Empezar en Foco» con una
/// sesión ya abierta) esa tarea se suma a la sesión y queda elegida.
class DungeonRequested extends DungeonEvent {
  const DungeonRequested({this.taskId});

  final String? taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Entrar con la duración, el ciclo y la mochila elegidos.
class DungeonStarted extends DungeonEvent {
  const DungeonStarted({
    required this.totalMinutes,
    required this.cycleMinutes,
    required this.taskIds,
    this.habitIds = const [],
  });

  final int totalMinutes;
  final int cycleMinutes;
  final List<String> taskIds;
  final List<String> habitIds;

  @override
  List<Object?> get props => [totalMinutes, cycleMinutes, taskIds, habitIds];
}

/// Pasó un segundo (lo envía el propio bloc).
class DungeonTicked extends DungeonEvent {
  const DungeonTicked();
}

class DungeonPauseToggled extends DungeonEvent {
  const DungeonPauseToggled();
}

class DungeonBreakSkipped extends DungeonEvent {
  const DungeonBreakSkipped();
}

/// La misión en la que se concentra el ciclo actual.
class DungeonTaskSelected extends DungeonEvent {
  const DungeonTaskSelected(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class DungeonTaskCompleted extends DungeonEvent {
  const DungeonTaskCompleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Marcar el paso actual de una tarea sin salir de Foco.
class DungeonStepDone extends DungeonEvent {
  const DungeonStepDone(this.stepId);

  final String stepId;

  @override
  List<Object?> get props => [stepId];
}

/// Cumplir hoy un hábito de la sesión.
class DungeonHabitDone extends DungeonEvent {
  const DungeonHabitDone(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// Terminar la sesión antes o después de agotar los ciclos. Con [allDone]
/// la cierra el propio bloc porque ya se cumplió todo lo de la sesión.
class DungeonEnded extends DungeonEvent {
  const DungeonEnded({this.allDone = false});

  final bool allDone;

  @override
  List<Object?> get props => [allDone];
}

/// Cerrar el resumen de la sesión terminada.
class DungeonSummaryDismissed extends DungeonEvent {
  const DungeonSummaryDismissed();
}
