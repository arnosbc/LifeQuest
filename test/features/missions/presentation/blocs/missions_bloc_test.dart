import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/set_mission_repeat.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';

import '../../../../helpers/mocks.dart';
import '../../missions_fixtures.dart';

void main() {
  late MockGetMissionsBoard getBoard;
  late MockCreateMission createMission;
  late MockCompleteMission completeMission;
  late _MockSetRepeat setRepeat;
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(newMission);
  });

  setUp(() {
    getBoard = MockGetMissionsBoard();
    createMission = MockCreateMission();
    completeMission = MockCompleteMission();
    setRepeat = _MockSetRepeat();
  });

  MissionsBloc build() => MissionsBloc(
    getMissionsBoard: getBoard,
    createMission: createMission,
    completeMission: completeMission,
    renameMission: MockRenameMission(),
    deleteMission: MockDeleteMission(),
    setMissionRepeat: setRepeat,
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
    'crear con Focus recarga y pide abrir Foco con la tarea nueva',
    setUp: () {
      when(
        () => createMission(any()),
      ).thenAnswer((_) async => const Right('t-new'));
      givenBoard(const Right(board));
    },
    build: build,
    seed: () => const MissionsSuccess(emptyBoard),
    act: (bloc) => bloc.add(const MissionCreated(newMission, startFocus: true)),
    expect: () => [
      const MissionsSuccess(emptyBoard, saving: true),
      const MissionsSuccess(
        board,
        message: 'Tarea creada. Tu sesión de foco te espera.',
        focusTaskId: 't-new',
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
      const MissionsSuccess(emptyBoard, message: '¡Tarea completada!'),
    ],
  );

  blocTest<MissionsBloc, MissionsState>(
    '073: elegir la repetición la guarda y recarga con aviso',
    setUp: () {
      when(
        () => setRepeat(const RepeatParams('t1', MissionRepeat.daily)),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(const Right(board));
    },
    build: build,
    seed: () => const MissionsSuccess(board),
    act: (bloc) => bloc.add(const MissionRepeatSet('t1', MissionRepeat.daily)),
    expect: () => [
      const MissionsSuccess(board, busyMissionId: 't1'),
      const MissionsSuccess(
        board,
        message: 'Listo: al completarla, vuelve sola en su día.',
      ),
    ],
  );
}

class _MockSetRepeat extends Mock implements SetMissionRepeat {}
