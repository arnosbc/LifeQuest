// Renombrar y borrar (028) en Misiones, Hábitos y Taverna: cada bloc marca
// el elemento ocupado, llama a su usecase y vuelve a leer.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/rename_habit.dart'
    as habits;
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/presentation/blocs/tavern_bloc.dart';

import '../helpers/mocks.dart';
import 'habits/habits_fixtures.dart';
import 'missions/missions_fixtures.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const habits.RenameParams('x', 'y'));
  });

  blocTest<MissionsBloc, MissionsState>(
    'borrar una misión la marca ocupada y vuelve a leer',
    build: () {
      final getBoard = MockGetMissionsBoard();
      final delete = MockDeleteMission();
      when(() => getBoard(any())).thenAnswer((_) async => const Right(board));
      when(() => delete('m1')).thenAnswer((_) async => const Right(unit));
      return MissionsBloc(
        getMissionsBoard: getBoard,
        createMission: MockCreateMission(),
        completeMission: MockCompleteMission(),
        renameMission: MockRenameMission(),
        deleteMission: delete,
      );
    },
    seed: () => const MissionsSuccess(board),
    act: (bloc) => bloc.add(const MissionDeleted('m1')),
    expect: () => [
      const MissionsSuccess(board, busyMissionId: 'm1'),
      const MissionsSuccess(board, message: 'Misión borrada.'),
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
      );
    },
    seed: () => const HabitsSuccess(habitsBoard),
    act: (bloc) => bloc.add(const HabitRenamed('h1', 'Leer 20 páginas')),
    expect: () => [
      const HabitsSuccess(habitsBoard, busyHabitId: 'h1'),
      const HabitsSuccess(habitsBoard, message: 'Hábito renombrado.'),
    ],
  );

  const tavern = TavernBoard(
    npcs: [Npc(id: 'n1', name: 'Vera', skillName: 'Salud')],
  );
  blocTest<TavernBloc, TavernState>(
    'si borrar el NPC falla, conserva la Taverna y avisa',
    build: () {
      final getBoard = MockGetTavernBoard();
      final delete = MockDeleteNpc();
      when(() => delete('n1')).thenAnswer(
        (_) async => const Left(ServerFailure('No encontramos ese NPC.')),
      );
      return TavernBloc(
        getBoard: getBoard,
        createNpc: MockCreateNpc(),
        acceptMission: MockAcceptNpcMission(),
        completeMission: MockCompleteNpcMission(),
        renameNpc: MockRenameNpc(),
        deleteNpc: delete,
      );
    },
    seed: () => const TavernSuccess(tavern),
    act: (bloc) => bloc.add(const NpcDeleted('n1')),
    expect: () => [
      const TavernSuccess(tavern, busyKey: 'n1'),
      const TavernSuccess(tavern, message: 'No encontramos ese NPC.'),
    ],
  );
}
