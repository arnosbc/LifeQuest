part of 'dungeon_bloc.dart';

sealed class DungeonEvent extends Equatable {
  const DungeonEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar la Mazmorra.
class DungeonRequested extends DungeonEvent {
  const DungeonRequested();
}

/// Entrar con la duración, el ciclo y la mochila elegidos.
class DungeonStarted extends DungeonEvent {
  const DungeonStarted({
    required this.totalMinutes,
    required this.cycleMinutes,
    required this.taskIds,
  });

  final int totalMinutes;
  final int cycleMinutes;
  final List<String> taskIds;

  @override
  List<Object?> get props => [totalMinutes, cycleMinutes, taskIds];
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

/// Terminar la sesión antes o después de agotar los ciclos.
class DungeonEnded extends DungeonEvent {
  const DungeonEnded();
}

/// Cerrar el resumen de la sesión terminada.
class DungeonSummaryDismissed extends DungeonEvent {
  const DungeonSummaryDismissed();
}
