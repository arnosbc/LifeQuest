import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';

import '../../helpers/mocks.dart';
import 'stage_fixtures.dart';

void main() {
  late MockGetStageBoard getBoard;
  late MockCreateProject createProject;
  late MockCreateGoal createGoal;
  late MockCompleteStageTask completeTask;
  late MockCreateResource createResource;
  late MockGetResourceUrl resourceUrl;
  late MockArchiveStageItem archive;
  late MockCompleteProject completeProject;
  final now = DateTime(2026, 10, 25, 9);
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(now);
    registerFallbackValue(newProject);
    registerFallbackValue(newGoal);
    registerFallbackValue(
      const NewResource(title: 't', kind: ResourceKind.link, url: 'u'),
    );
    registerFallbackValue(const StageResource(id: 'r', title: 't'));
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
    resourceUrl = MockGetResourceUrl();
    archive = MockArchiveStageItem();
    completeProject = MockCompleteProject();
  });

  StageBloc build() => StageBloc(
    getStageBoard: getBoard,
    createProject: createProject,
    createGoal: createGoal,
    completeTask: completeTask,
    createResource: createResource,
    resourceUrl: resourceUrl,
    archive: archive,
    completeProject: completeProject,
    clock: () => now,
  );

  void givenBoard(Either<Failure, StageBoard> result) =>
      when(() => getBoard(any())).thenAnswer((_) async => result);

  const note = NewResource(
    title: 'Apuntes de Bloc',
    kind: ResourceKind.note,
    content: 'Un Bloc recibe eventos y emite estados.',
    projectId: 'p1',
  );
  const doc = StageResource(
    id: 'r2',
    title: 'Enunciado',
    kind: ResourceKind.document,
    path: 'u/enunciado.pdf',
    bucket: 'resources',
  );

  blocTest<StageBloc, StageState>(
    'guardar una nota la crea y avisa según su tipo',
    setUp: () {
      when(
        () => createResource(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(stageBoard));
    },
    build: build,
    seed: () => const StageSuccess(stageBoard),
    act: (bloc) => bloc.add(const StageResourceCreated(note)),
    expect: () => [
      const StageSuccess(stageBoard, busy: true),
      const StageSuccess(stageBoard, message: 'Nota guardada en tus Recursos.'),
    ],
    verify: (_) => verify(() => createResource(note)).called(1),
  );

  blocTest<StageBloc, StageState>(
    'abrir un documento pide su enlace temporal para que la pantalla lo abra',
    setUp: () => when(
      () => resourceUrl(doc),
    ).thenAnswer((_) async => const Right('https://firmado/enunciado.pdf')),
    build: build,
    seed: () => const StageSuccess(stageBoard),
    act: (bloc) => bloc.add(const StageResourceOpened(doc)),
    expect: () => [
      const StageSuccess(stageBoard, busy: true),
      const StageSuccess(stageBoard, openUrl: 'https://firmado/enunciado.pdf'),
    ],
  );

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
