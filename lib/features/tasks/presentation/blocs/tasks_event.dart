part of 'tasks_bloc.dart';

sealed class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar la pantalla Tareas.
class TasksRequested extends TasksEvent {
  const TasksRequested();
}

/// El usuario guardó una tarea nueva; [startFocus] abre luego Foco.
/// «Ya la hice»: se oculta y se completa al acabar la ventana de deshacer.
class TaskDoneStaged extends TasksEvent {
  const TaskDoneStaged(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// «Deshacer» dentro de la ventana: la tarea vuelve sin tocar el servidor.
class TaskDoneUndone extends TasksEvent {
  const TaskDoneUndone(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Completar ya en el servidor (lo dispara la ventana de deshacer).
class TaskCompleted extends TasksEvent {
  const TaskCompleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class TaskRenamed extends TasksEvent {
  const TaskRenamed(this.taskId, this.title);

  final String taskId;
  final String title;

  @override
  List<Object?> get props => [taskId, title];
}

/// Guardó la hoja de editar.
class TaskEdited extends TasksEvent {
  const TaskEdited(this.taskId, this.task);

  final String taskId;
  final NewTask task;

  @override
  List<Object?> get props => [taskId, task];
}

class TaskDeleted extends TasksEvent {
  const TaskDeleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}
