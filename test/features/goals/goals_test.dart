import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/goals/data/models/goals_board_model.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';
import 'package:proyecto_movil/features/goals/presentation/blocs/goals_bloc.dart';

import '../../helpers/mocks.dart';

const attack = BossAttack(
  kind: AttackKind.task,
  id: 't1',
  title: 'Primera salida',
  damage: 30,
);
const alive = GoalsBoard(
  goals: [
    BossGoal(id: 'g1', title: 'Maratón', currentHp: 30, attacks: [attack]),
  ],
);
const defeated = GoalsBoard(
  goals: [
    BossGoal(
      id: 'g1',
      title: 'Maratón',
      currentHp: 0,
      status: GoalStatus.completed,
    ),
  ],
);

void main() {
  test('GoalsBoardModel convierte goals_overview', () {
    final goal = GoalsBoardModel.fromJson({
      'goals': [
        {
          'id': 'g1',
          'title': 'Maratón',
          'status': 'in_progress',
          'due_date': '2026-12-01',
          'skill_name': 'Salud',
          'boss_max_hp': 100,
          'boss_current_hp': 60,
          'smart': {'specific': 's', 'measurable': 'm'},
          'attacks': [
            {'kind': 'project', 'id': 'p1', 'title': 'Plan', 'damage': 30},
          ],
          'hits': [
            {
              'title': 'Salida',
              'damage': 40,
              'at': '2026-10-27T10:00:00+00:00',
            },
          ],
        },
      ],
      'victory_xp': 300,
      'victory_coins': 90,
    }).toEntity().goals.single;

    expect(
      [goal.status, goal.currentHp, goal.active],
      [GoalStatus.inProgress, 60, true],
    );
    expect(goal.attacks.single.kind, AttackKind.project);
    expect(goal.hits.single.damage, 40);
    expect(goal.smart.measurable, 'm');
  });

  group('GoalsBloc', () {
    late MockGetGoalsBoard getBoard;
    late MockAttackBoss attackBoss;

    setUpAll(() {
      registerFallbackValue(const NoParams());
      registerFallbackValue(attack);
    });

    setUp(() {
      getBoard = MockGetGoalsBoard();
      attackBoss = MockAttackBoss();
      when(() => attackBoss(any())).thenAnswer((_) async => const Right(unit));
    });

    GoalsBloc build() => GoalsBloc(
      getBoard: getBoard,
      attack: attackBoss,
      archive: MockArchiveGoal(),
    );

    blocTest<GoalsBloc, GoalsState>(
      'un golpe que no vence al jefe avisa el daño',
      setUp: () => when(
        () => getBoard(any()),
      ).thenAnswer((_) async => const Right(alive)),
      build: build,
      seed: () => const GoalsSuccess(alive),
      act: (bloc) => bloc.add(const BossAttacked(goalId: 'g1', attack: attack)),
      expect: () => [
        const GoalsSuccess(alive, busyKey: 't1'),
        const GoalsSuccess(
          alive,
          message: '¡Golpe certero! −30 de vida al jefe.',
        ),
      ],
    );

    blocTest<GoalsBloc, GoalsState>(
      'si el jefe cae, anuncia la victoria con su premio',
      setUp: () => when(
        () => getBoard(any()),
      ).thenAnswer((_) async => const Right(defeated)),
      build: build,
      seed: () => const GoalsSuccess(alive),
      act: (bloc) => bloc.add(const BossAttacked(goalId: 'g1', attack: attack)),
      skip: 1,
      expect: () => [
        const GoalsSuccess(
          defeated,
          message: '¡Victoria! Venciste al jefe: +300 XP y +90 Monedas.',
        ),
      ],
    );
  });
}
