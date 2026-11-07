import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/presentation/blocs/tasks_bloc.dart';

import '../../../../helpers/mocks.dart';
import '../../tasks_fixtures.dart';

void main() {
  late MockGetTasksBoard getBoard;
  late MockCompleteTask completeTask;
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(newTask);
  });

  setUp(() {
    getBoard = MockGetTasksBoard();
    completeTask = MockCompleteTask();
  });

  TasksBloc build() => TasksBloc(
    getTasksBoard: getBoard,
    completeTask: completeTask,
    renameTask: MockRenameTask(),
    deleteTask: MockDeleteTask(),
    updateTask: MockUpdateTask(),
  );

  void givenBoard(Either<Failure, TasksBoard> result) =>
      when(() => getBoard(any())).thenAnswer((_) async => result);

  blocTest<TasksBloc, TasksState>(
    'la primera carga pasa por Loading y termina en Success',
    setUp: () => givenBoard(const Right(board)),
    build: build,
    act: (bloc) => bloc.add(const TasksRequested()),
    expect: () => [const TasksLoading(), const TasksSuccess(board)],
  );

  blocTest<TasksBloc, TasksState>(
    'si la primera carga falla, muestra el error',
    setUp: () => givenBoard(const Left(failure)),
    build: build,
    act: (bloc) => bloc.add(const TasksRequested()),
    expect: () => [const TasksLoading(), TasksFailure(failure.message)],
  );

  blocTest<TasksBloc, TasksState>(
    'completar marca la tarea ocupada y vuelve a leer el tablero',
    setUp: () {
      when(() => completeTask('t1')).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(emptyBoard));
    },
    build: build,
    seed: () => const TasksSuccess(board),
    act: (bloc) => bloc.add(const TaskCompleted('t1')),
    expect: () => [
      const TasksSuccess(board, busyTaskId: 't1', hidden: {'t1'}),
      const TasksSuccess(
        emptyBoard,
        message: '¡Tarea completada!',
        hidden: {'t1'},
      ),
    ],
  );

  blocTest<TasksBloc, TasksState>(
    '«Ya la hice» oculta la tarea y la completa al cerrar la ventana',
    setUp: () {
      when(() => completeTask('t1')).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(emptyBoard));
    },
    build: () => TasksBloc(
      getTasksBoard: getBoard,
      completeTask: completeTask,
      renameTask: MockRenameTask(),
      deleteTask: MockDeleteTask(),
      updateTask: MockUpdateTask(),
      undoWindow: const Duration(milliseconds: 10),
    ),
    seed: () => const TasksSuccess(board),
    act: (bloc) => bloc.add(const TaskDoneStaged('t1')),
    wait: const Duration(milliseconds: 50),
    expect: () => [
      const TasksSuccess(board, hidden: {'t1'}, undoTaskId: 't1'),
      const TasksSuccess(board, busyTaskId: 't1', hidden: {'t1'}),
      const TasksSuccess(
        emptyBoard,
        message: '¡Tarea completada!',
        hidden: {'t1'},
      ),
    ],
    verify: (_) => verify(() => completeTask('t1')).called(1),
  );

  blocTest<TasksBloc, TasksState>(
    'Deshacer dentro de la ventana no toca el servidor',
    build: () => TasksBloc(
      getTasksBoard: getBoard,
      completeTask: completeTask,
      renameTask: MockRenameTask(),
      deleteTask: MockDeleteTask(),
      updateTask: MockUpdateTask(),
      undoWindow: const Duration(milliseconds: 20),
    ),
    seed: () => const TasksSuccess(board),
    act: (bloc) => bloc
      ..add(const TaskDoneStaged('t1'))
      ..add(const TaskDoneUndone('t1')),
    wait: const Duration(milliseconds: 60),
    expect: () => [
      const TasksSuccess(board, hidden: {'t1'}, undoTaskId: 't1'),
      const TasksSuccess(board),
    ],
    verify: (_) => verifyNever(() => completeTask(any())),
  );
}
