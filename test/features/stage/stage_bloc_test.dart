import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_resource.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';

import '../../helpers/mocks.dart';
import 'stage_fixtures.dart';

void main() {
  late MockGetStageBoard getBoard;
  late MockCreateProject createProject;
  late MockCreateGoal createGoal;
  late MockCompleteStageTask completeTask;
  late MockCreateResource createResource;
  late MockArchiveStageItem archive;
  late MockCompleteProject completeProject;
  final now = DateTime(2026, 10, 25, 9);
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(now);
    registerFallbackValue(newProject);
    registerFallbackValue(newGoal);
    registerFallbackValue(const CreateResourceParams(title: 't', url: 'u'));
    registerFallbackValue(
      const ArchiveStageItemParams(kind: StageItemKind.project, id: 'p'),
    );
  });

  setUp(() {
    getBoard = MockGetStageBoard();
    createProject = MockCreateProject();
    createGoal = MockCreateGoal();
    completeTask = MockCompleteStageTask();
    createResource = MockCreateResource();
    archive = MockArchiveStageItem();
    completeProject = MockCompleteProject();
  });

  StageBloc build() => StageBloc(
    getStageBoard: getBoard,
    createProject: createProject,
    createGoal: createGoal,
    completeTask: completeTask,
    createResource: createResource,
    archive: archive,
    completeProject: completeProject,
    clock: () => now,
  );

  void givenBoard(Either<Failure, StageBoard> result) =>
      when(() => getBoard(any())).thenAnswer((_) async => result);

  blocTest<StageBloc, StageState>(
    'la primera carga pasa por Loading y termina en Success',
    setUp: () => givenBoard(const Right(stageBoard)),
    build: build,
    act: (bloc) => bloc.add(const StageRequested()),
    expect: () => [const StageLoading(), const StageSuccess(stageBoard)],
    verify: (_) => verify(() => getBoard(now)).called(1),
  );

  blocTest<StageBloc, StageState>(
    'si la primera carga falla, muestra el error',
    setUp: () => givenBoard(const Left(failure)),
    build: build,
    act: (bloc) => bloc.add(const StageRequested()),
    expect: () => [const StageLoading(), StageFailure(failure.message)],
  );

  blocTest<StageBloc, StageState>(
    'crear un proyecto vuelve a leer el tablero',
    setUp: () {
      when(
        () => createProject(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(stageBoard));
    },
    build: build,
    seed: () => const StageSuccess(emptyStageBoard),
    act: (bloc) => bloc.add(const StageProjectCreated(newProject)),
    expect: () => [
      const StageSuccess(emptyStageBoard, busy: true),
      const StageSuccess(
        stageBoard,
        message: 'Proyecto creado. Añádele misiones para avanzar.',
      ),
    ],
    verify: (_) => verify(() => createProject(newProject)).called(1),
  );

  blocTest<StageBloc, StageState>(
    'archivar envía el tipo y el id',
    setUp: () {
      when(() => archive(any())).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(emptyStageBoard));
    },
    build: build,
    seed: () => const StageSuccess(stageBoard),
    act: (bloc) => bloc.add(
      const StageItemArchived(kind: StageItemKind.resource, id: 'r1'),
    ),
    skip: 1,
    expect: () => [
      const StageSuccess(emptyStageBoard, message: 'Enviado al Archivo.'),
    ],
    verify: (_) => verify(
      () => archive(
        const ArchiveStageItemParams(kind: StageItemKind.resource, id: 'r1'),
      ),
    ).called(1),
  );

  blocTest<StageBloc, StageState>(
    'si completar el proyecto falla, conserva los datos y avisa',
    setUp: () => when(
      () => completeProject('p1'),
    ).thenAnswer((_) async => const Left(failure)),
    build: build,
    seed: () => const StageSuccess(stageBoard),
    act: (bloc) => bloc.add(const StageProjectCompleted('p1')),
    expect: () => [
      const StageSuccess(stageBoard, busy: true),
      StageSuccess(stageBoard, message: failure.message),
    ],
    verify: (_) => verifyNever(() => getBoard(any())),
  );

  blocTest<StageBloc, StageState>(
    'crear una meta vuelve a leer el tablero',
    setUp: () {
      when(() => createGoal(any())).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(stageBoard));
    },
    build: build,
    seed: () => const StageSuccess(emptyStageBoard),
    act: (bloc) => bloc.add(StageGoalCreated(newGoal)),
    expect: () => [
      const StageSuccess(emptyStageBoard, busy: true),
      const StageSuccess(
        stageBoard,
        message: '¡Nueva meta! Un jefe aparece en el horizonte.',
      ),
    ],
    verify: (_) => verify(() => createGoal(newGoal)).called(1),
  );

  blocTest<StageBloc, StageState>(
    'completar una misión del proyecto vuelve a leer el tablero',
    setUp: () {
      when(() => completeTask('t1')).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(emptyStageBoard));
    },
    build: build,
    seed: () => const StageSuccess(stageBoard),
    act: (bloc) => bloc.add(const StageTaskCompleted('t1')),
    skip: 1,
    expect: () => [
      const StageSuccess(
        emptyStageBoard,
        message: '¡Misión completada! Tu héroe se hace más fuerte.',
      ),
    ],
  );
}
