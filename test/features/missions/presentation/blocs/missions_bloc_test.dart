import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';

import '../../../../helpers/mocks.dart';
import '../../missions_fixtures.dart';

void main() {
  late MockGetMissionsBoard getBoard;
  late MockCreateMission createMission;
  late MockCompleteMission completeMission;
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(newMission);
  });

  setUp(() {
    getBoard = MockGetMissionsBoard();
    createMission = MockCreateMission();
    completeMission = MockCompleteMission();
  });

  MissionsBloc build() => MissionsBloc(
    getMissionsBoard: getBoard,
    createMission: createMission,
    completeMission: completeMission,
    renameMission: MockRenameMission(),
    deleteMission: MockDeleteMission(),
  );

  void givenBoard(Either<Failure, MissionsBoard> result) =>
      when(() => getBoard(any())).thenAnswer((_) async => result);

  blocTest<MissionsBloc, MissionsState>(
    'la primera carga pasa por Loading y termina en Success',
    setUp: () => givenBoard(const Right(board)),
    build: build,
    act: (bloc) => bloc.add(const MissionsRequested()),
    expect: () => [const MissionsLoading(), const MissionsSuccess(board)],
  );

  blocTest<MissionsBloc, MissionsState>(
    'si la primera carga falla, muestra el error',
    setUp: () => givenBoard(const Left(failure)),
    build: build,
    act: (bloc) => bloc.add(const MissionsRequested()),
    expect: () => [const MissionsLoading(), MissionsFailure(failure.message)],
  );

  blocTest<MissionsBloc, MissionsState>(
    'crear con Focus recarga y pide abrir la Mazmorra',
    setUp: () {
      when(
        () => createMission(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(board));
    },
    build: build,
    seed: () => const MissionsSuccess(emptyBoard),
    act: (bloc) => bloc.add(const MissionCreated(newMission, startFocus: true)),
    expect: () => [
      const MissionsSuccess(emptyBoard, saving: true),
      const MissionsSuccess(
        board,
        message: 'Misión creada. ¡Tu sesión de enfoque te espera!',
        focusRequested: true,
      ),
    ],
    verify: (_) => verify(() => createMission(newMission)).called(1),
  );

  blocTest<MissionsBloc, MissionsState>(
    'si crear falla, conserva los datos y avisa',
    setUp: () => when(
      () => createMission(any()),
    ).thenAnswer((_) async => const Left(failure)),
    build: build,
    seed: () => const MissionsSuccess(board),
    act: (bloc) => bloc.add(const MissionCreated(newMission)),
    expect: () => [
      const MissionsSuccess(board, saving: true),
      MissionsSuccess(board, message: failure.message),
    ],
    verify: (_) => verifyNever(() => getBoard(any())),
  );

  blocTest<MissionsBloc, MissionsState>(
    'completar marca la misión ocupada y vuelve a leer el tablero',
    setUp: () {
      when(
        () => completeMission('t1'),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(emptyBoard));
    },
    build: build,
    seed: () => const MissionsSuccess(board),
    act: (bloc) => bloc.add(const MissionCompleted('t1')),
    expect: () => [
      const MissionsSuccess(board, busyMissionId: 't1'),
      const MissionsSuccess(
        emptyBoard,
        message: '¡Misión completada! Tu héroe se hace más fuerte.',
      ),
    ],
  );
}
