import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/complete_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/delete_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/get_tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/rename_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/update_task.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({
    required this._getTasksBoard,
    required this._completeTask,
    required this._renameTask,
    required this._deleteTask,
    required this._updateTask,
    this.undoWindow = const Duration(seconds: 5),
  }) : super(const TasksInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<TasksRequested>(_onRequested, transformer: droppable());
    // sequential: varias ventanas de deshacer pueden cerrarse seguidas.
    on<TaskCompleted>(_onCompleted, transformer: sequential());
    on<TaskDoneStaged>(_onStaged);
    on<TaskDoneUndone>(_onUndone);
    on<TaskRenamed>(
      (e, emit) => _change(
        emit,
        e.taskId,
        () => _renameTask(RenameParams(e.taskId, e.title)),
        'Tarea renombrada.',
      ),
      transformer: droppable(),
    );
    on<TaskEdited>(
      (e, emit) => _change(
        emit,
        e.taskId,
        () => _updateTask((id: e.taskId, task: e.task)),
        'Tarea actualizada.',
      ),
      transformer: droppable(),
    );
    on<TaskDeleted>(
      (e, emit) => _change(
        emit,
        e.taskId,
        () => _deleteTask(e.taskId),
        'Tarea borrada.',
      ),
      transformer: droppable(),
    );
  }

  /// Tiempo para «Deshacer» antes de completar (y cobrar) en el servidor.
  final Duration undoWindow;

  final _staged = <String, Timer>{};
  final _completing = <String>{};

  /// Éxito con las tareas en vuelo ocultas.
  TasksSuccess _ok(
    TasksBoard board, {
    bool refreshing = false,
    String? busyTaskId,
    String? message,
    String? undoTaskId,
  }) => TasksSuccess(
    board,
    refreshing: refreshing,
    busyTaskId: busyTaskId,
    message: message,
    hidden: {..._staged.keys, ..._completing},
    undoTaskId: undoTaskId,
  );

  void _onStaged(TaskDoneStaged event, Emitter<TasksState> emit) {
    final current = state;
    if (current is! TasksSuccess || current.hidden.contains(event.taskId)) {
      return;
    }
    _staged[event.taskId] = Timer(
      undoWindow,
      () => add(TaskCompleted(event.taskId)),
    );
    emit(_ok(current.board, undoTaskId: event.taskId));
  }

  void _onUndone(TaskDoneUndone event, Emitter<TasksState> emit) {
    final current = state;
    if (current is! TasksSuccess) return;
    _staged.remove(event.taskId)?.cancel();
    emit(_ok(current.board));
  }

  @override
  Future<void> close() {
    // Salir de la pantalla no pierde lo marcado: se completa ya.
    for (final MapEntry(:key, :value) in _staged.entries) {
      value.cancel();
      unawaited(_completeTask(key));
    }
    _staged.clear();
    return super.close();
  }

  final GetTasksBoard _getTasksBoard;
  final UpdateTask _updateTask;
  final CompleteTask _completeTask;
  final RenameTask _renameTask;
  final DeleteTask _deleteTask;

  Future<void> _onRequested(
    TasksRequested event,
    Emitter<TasksState> emit,
  ) async {
    final current = state;
    emit(
      current is TasksSuccess
          ? _ok(current.board, refreshing: true)
          : const TasksLoading(),
    );
    final result = await _getTasksBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is TasksSuccess
            ? _ok(current.board, message: failure.message)
            : TasksFailure(failure.message),
        _ok,
      ),
    );
  }

  Future<void> _onCompleted(
    TaskCompleted event,
    Emitter<TasksState> emit,
  ) async {
    final current = state;
    if (current is! TasksSuccess) return;
    _staged.remove(event.taskId)?.cancel();
    _completing.add(event.taskId);
    emit(_ok(current.board, busyTaskId: event.taskId));
    final completed = await _completeTask(event.taskId);
    if (completed case Left(value: final failure)) {
      _completing.remove(event.taskId);
      emit(_ok(current.board, message: failure.message));
      return;
    }
    await _reload(emit, current.board, '¡Tarea completada!');
    _completing.remove(event.taskId);
  }

  /// XP, Monedas y orden los decide el servidor: se vuelven a leer.
  Future<void> _reload(
    Emitter<TasksState> emit,
    TasksBoard previous,
    String message,
  ) async {
    final reloaded = await _getTasksBoard(const NoParams());
    emit(
      reloaded.match(
        (failure) => _ok(previous, message: failure.message),
        (board) => _ok(board, message: message),
      ),
    );
  }

  Future<void> _change(
    Emitter<TasksState> emit,
    String taskId,
    Future<Either<Failure, Unit>> Function() action,
    String message,
  ) async {
    final current = state;
    if (current is! TasksSuccess) return;
    emit(_ok(current.board, busyTaskId: taskId));
    if (await action() case Left(value: final failure)) {
      emit(_ok(current.board, message: failure.message));
      return;
    }
    await _reload(emit, current.board, message);
  }
}
