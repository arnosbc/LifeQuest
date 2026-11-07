part of 'tasks_bloc.dart';

sealed class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class TasksLoading extends TasksState {
  const TasksLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class TasksSuccess extends TasksState {
  const TasksSuccess(
    this.board, {
    this.refreshing = false,
    this.busyTaskId,
    this.message,
    this.hidden = const {},
    this.undoTaskId,
  });

  /// Tareas marcadas como hechas que aún se pueden deshacer o se completan.
  final Set<String> hidden;

  /// Recién marcada: mostrar «Deshacer».
  final String? undoTaskId;

  /// Las tareas que se ven (sin las [hidden]).
  List<Task> get visibleTasks => [
    for (final t in board.tasks)
      if (!hidden.contains(t.id)) t,
  ];

  final TasksBoard board;

  /// Refresco en curso (deslizar hacia abajo).
  final bool refreshing;

  /// Tarea que se está completando.
  final String? busyTaskId;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [
    board,
    refreshing,
    busyTaskId,
    message,
    hidden,
    undoTaskId,
  ];
}

/// La primera carga falló; no hay datos que mostrar.
class TasksFailure extends TasksState {
  const TasksFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
