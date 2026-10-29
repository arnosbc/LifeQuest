import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/data/models/tavern_board_model.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/accept_npc_mission.dart';
import 'package:proyecto_movil/features/tavern/presentation/blocs/tavern_bloc.dart';

import '../../helpers/mocks.dart';

const vera = Npc(id: 'n1', name: 'Vera', skillName: 'Salud');
const board = TavernBoard(npcs: [vera], npcLimit: 3);

void main() {
  test('TavernBoardModel convierte tavern_overview', () {
    final entity = TavernBoardModel.fromJson({
      'npcs': [
        {
          'id': 'n1',
          'name': 'Vera',
          'noble_mission': 'Que corras',
          'frequency': 'daily',
          'skill_name': 'Salud',
          'free_at': '2026-10-27T18:00:00+00:00',
          'open_mission': {'id': 't1', 'title': 'Correr 5 km', 'xp_reward': 10},
          'completed': 2,
        },
      ],
      'npc_limit': 4,
      'instant_cost': 15,
      'coins': 88,
      'skills': [
        {'id': 's1', 'name': 'Salud'},
      ],
    }).toEntity();

    final npc = entity.npcs.single;
    expect(npc.frequency, NpcFrequency.daily);
    expect(
      npc.openMission,
      const NpcMission(id: 't1', title: 'Correr 5 km', xpReward: 10),
    );
    expect(npc.isFree(DateTime.utc(2026, 10, 27, 17)), isFalse);
    expect(npc.isFree(DateTime.utc(2026, 10, 27, 19)), isTrue);
    expect([entity.npcLimit, entity.full], [4, false]);
  });

  group('TavernBloc', () {
    late MockGetTavernBoard getBoard;
    late MockAcceptNpcMission accept;
    late MockCompleteNpcMission complete;
    late MockSuggestNpcMission suggest;

    setUpAll(() {
      registerFallbackValue(const NoParams());
      registerFallbackValue(
        const AcceptNpcMissionParams(npcId: 'n', title: 't'),
      );
    });

    setUp(() {
      getBoard = MockGetTavernBoard();
      accept = MockAcceptNpcMission();
      complete = MockCompleteNpcMission();
      suggest = MockSuggestNpcMission();
      when(() => getBoard(any())).thenAnswer((_) async => const Right(board));
    });

    TavernBloc build() => TavernBloc(
      getBoard: getBoard,
      createNpc: MockCreateNpc(),
      suggestMission: suggest,
      acceptMission: accept,
      completeMission: complete,
      renameNpc: MockRenameNpc(),
      deleteNpc: MockDeleteNpc(),
    );

    blocTest<TavernBloc, TavernState>(
      'aceptar una misión la crea y vuelve a leer',
      setUp: () =>
          when(() => accept(any())).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) =>
          bloc.add(const NpcMissionAccepted(npcId: 'n1', title: 'Correr')),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(
          board,
          message: 'Misión aceptada. Ya está en tu Stage.',
        ),
      ],
      verify: (_) => verify(
        () =>
            accept(const AcceptNpcMissionParams(npcId: 'n1', title: 'Correr')),
      ).called(1),
    );

    blocTest<TavernBloc, TavernState>(
      'pedir misión: RPGenie la redacta y se acepta sola',
      setUp: () {
        when(
          () => suggest('n1'),
        ).thenAnswer((_) async => const Right('Diseña 3 logos'));
        when(() => accept(any())).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) => bloc.add(const NpcMissionRequested(vera)),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(
          board,
          message: 'Nueva misión de Vera: Diseña 3 logos',
        ),
      ],
      verify: (_) => verify(
        () => accept(
          const AcceptNpcMissionParams(npcId: 'n1', title: 'Diseña 3 logos'),
        ),
      ).called(1),
    );

    blocTest<TavernBloc, TavernState>(
      'si RPGenie falla, avisa y no crea ni cobra nada',
      setUp: () => when(
        () => suggest('n1'),
      ).thenAnswer((_) async => const Left(ServerFailure('sin cupo'))),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) => bloc.add(const NpcMissionRequested(vera)),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(board, message: 'sin cupo'),
      ],
      verify: (_) => verifyNever(() => accept(any())),
    );

    blocTest<TavernBloc, TavernState>(
      'si cumplir falla, conserva los datos y avisa',
      setUp: () => when(() => complete(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Ya estaba cerrada.')),
      ),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) =>
          bloc.add(const NpcMissionCompleted(npcId: 'n1', taskId: 't1')),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(board, message: 'Ya estaba cerrada.'),
      ],
    );
  });
}
