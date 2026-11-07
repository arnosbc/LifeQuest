// Renombrar, borrar (028), editar tareas y avisos de hábitos (034) en Tareas y Hábitos: cada bloc marca
// el elemento ocupado, llama a su usecase y vuelve a leer.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/rename_habit.dart'
    as habits;
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';
import 'package:proyecto_movil/features/tasks/presentation/blocs/tasks_bloc.dart';

import '../helpers/mocks.dart';
import 'habits/habits_fixtures.dart';
import 'tasks/tasks_fixtures.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const habits.RenameParams('x', 'y'));
  });

  blocTest<TasksBloc, TasksState>(
    'borrar una tarea la marca ocupada y vuelve a leer',
    build: () {
      final getBoard = MockGetTasksBoard();
      final delete = MockDeleteTask();
      when(() => getBoard(any())).thenAnswer((_) async => const Right(board));
      when(() => delete('m1')).thenAnswer((_) async => const Right(unit));
      return TasksBloc(
        getTasksBoard: getBoard,
        completeTask: MockCompleteTask(),
        renameTask: MockRenameTask(),
        deleteTask: delete,
        updateTask: MockUpdateTask(),
      );
    },
    seed: () => const TasksSuccess(board),
    act: (bloc) => bloc.add(const TaskDeleted('m1')),
    expect: () => [
      const TasksSuccess(board, busyTaskId: 'm1'),
      const TasksSuccess(board, message: 'Tarea borrada.'),
    ],
  );

  blocTest<HabitsBloc, HabitsState>(
    'renombrar un hábito envía el nombre nuevo',
    build: () {
      final getBoard = MockGetHabitsBoard();
      final rename = MockRenameHabit();
      when(
        () => getBoard(any()),
      ).thenAnswer((_) async => const Right(habitsBoard));
      when(() => rename(any())).thenAnswer((_) async => const Right(unit));
      return HabitsBloc(
        getHabitsBoard: getBoard,
        createHabit: MockCreateHabit(),
        completeGoodHabit: MockCompleteGoodHabit(),
        registerBadHabit: MockRegisterBadHabit(),
        renameHabit: rename,
        deleteHabit: MockDeleteHabit(),
        setHabitReminder: MockSetHabitReminder(),
      );
    },
    seed: () => const HabitsSuccess(habitsBoard),
    act: (bloc) => bloc.add(const HabitRenamed('h1', 'Leer 20 páginas')),
    expect: () => [
      const HabitsSuccess(habitsBoard, busyHabitId: 'h1'),
      const HabitsSuccess(habitsBoard, message: 'Hábito renombrado.'),
    ],
  );

  blocTest<TasksBloc, TasksState>(
    'editar una tarea envía los cambios y vuelve a leer',
    build: () {
      final getBoard = MockGetTasksBoard();
      final update = MockUpdateTask();
      when(() => getBoard(any())).thenAnswer((_) async => const Right(board));
      when(
        () => update((id: 'm1', task: const NewTask(title: 'Leer más'))),
      ).thenAnswer((_) async => const Right(unit));
      return TasksBloc(
        getTasksBoard: getBoard,
        completeTask: MockCompleteTask(),
        renameTask: MockRenameTask(),
        deleteTask: MockDeleteTask(),
        updateTask: update,
      );
    },
    seed: () => const TasksSuccess(board),
    act: (bloc) => bloc.add(const TaskEdited('m1', NewTask(title: 'Leer más'))),
    expect: () => [
      const TasksSuccess(board, busyTaskId: 'm1'),
      const TasksSuccess(board, message: 'Tarea actualizada.'),
    ],
  );

  blocTest<HabitsBloc, HabitsState>(
    'cambiar y quitar el aviso de un hábito',
    build: () {
      final getBoard = MockGetHabitsBoard();
      final reminder = MockSetHabitReminder();
      when(
        () => getBoard(any()),
      ).thenAnswer((_) async => const Right(habitsBoard));
      when(
        () => reminder((id: 'h1', minuteOfDay: 450)),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => reminder((id: 'h1', minuteOfDay: null)),
      ).thenAnswer((_) async => const Right(unit));
      return HabitsBloc(
        getHabitsBoard: getBoard,
        createHabit: MockCreateHabit(),
        completeGoodHabit: MockCompleteGoodHabit(),
        registerBadHabit: MockRegisterBadHabit(),
        renameHabit: MockRenameHabit(),
        deleteHabit: MockDeleteHabit(),
        setHabitReminder: reminder,
      );
    },
    seed: () => const HabitsSuccess(habitsBoard),
    act: (bloc) async {
      bloc.add(const HabitReminderChanged('h1', 450));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HabitReminderChanged('h1', null));
    },
    expect: () => [
      const HabitsSuccess(habitsBoard, busyHabitId: 'h1'),
      const HabitsSuccess(habitsBoard, message: 'Aviso guardado.'),
      const HabitsSuccess(habitsBoard, busyHabitId: 'h1'),
      const HabitsSuccess(habitsBoard, message: 'Aviso quitado.'),
    ],
  );
}
