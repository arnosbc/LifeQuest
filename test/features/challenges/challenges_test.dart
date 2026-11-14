import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/challenges/data/models/challenges_board_model.dart';
import 'package:proyecto_movil/features/challenges/domain/entities/challenges_board.dart';
import 'package:proyecto_movil/features/challenges/domain/usecases/claim_challenge.dart';
import 'package:proyecto_movil/features/challenges/domain/usecases/get_challenges.dart';
import 'package:proyecto_movil/features/challenges/presentation/blocs/challenges_bloc.dart';

class _MockGet extends Mock implements GetChallenges {}

class _MockClaim extends Mock implements ClaimChallenge {}

const _board = ChallengesBoard(
  daily: [
    DailyChallenge(
      key: 'xp',
      progress: 40,
      target: 30,
      coins: 5,
      claimed: false,
    ),
  ],
  month: MonthChallenge(
    progress: 1,
    target: 30,
    coins: 60,
    claimed: false,
    daysLeft: 17,
  ),
  league: League(
    division: 1,
    daysLeft: 2,
    xp: 50,
    rivals: [
      Rival(name: 'Aria', xp: 80),
      Rival(name: 'Bruno', xp: 50),
    ],
  ),
);

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  test('la tabla ordena por XP, el usuario gana los empates', () {
    expect(_board.league.standings.map((r) => r?.name), [
      'Aria',
      null,
      'Bruno',
    ]);
    expect(_board.league.rank, 2);
  });

  test('el modelo lee challenges_overview y el resultado de la liga', () {
    final board = ChallengesBoardModel.fromJson({
      'daily': [
        {
          'key': 'tasks',
          'progress': 2,
          'target': 2,
          'coins': 5,
          'claimed': false,
        },
      ],
      'month': {
        'progress': 3,
        'target': 30,
        'coins': 60,
        'claimed': false,
        'days_left': 4,
      },
      'league': {
        'division': 2,
        'last_result': 'promoted',
        'days_left': 3,
        'xp': 10,
        'rivals': [
          {'name': 'Iris', 'xp': 7},
        ],
      },
    }).toEntity();
    expect(board.daily.single.ready, isTrue);
    expect(board.month.daysLeft, 4);
    expect(board.league.lastResult, LeagueResult.promoted);
    expect(board.league.rank, 1);
  });

  group('ChallengesBloc', () {
    late _MockGet get;
    late _MockClaim claim;

    setUp(() {
      get = _MockGet();
      claim = _MockClaim();
      when(() => get(any())).thenAnswer((_) async => const Right(_board));
    });

    blocTest<ChallengesBloc, ChallengesState>(
      'cobra el cofre y recarga',
      build: () => ChallengesBloc(getChallenges: get, claimChallenge: claim),
      seed: () => const ChallengesSuccess(_board),
      setUp: () =>
          when(() => claim('xp')).thenAnswer((_) async => const Right(unit)),
      act: (b) => b.add(const ChallengeClaimed('xp')),
      expect: () => const [
        ChallengesSuccess(_board, claimingKey: 'xp'),
        ChallengesSuccess(_board),
      ],
      verify: (_) => verify(() => claim('xp')).called(1),
    );

    blocTest<ChallengesBloc, ChallengesState>(
      'si el cobro falla, avisa y conserva el tablero',
      build: () => ChallengesBloc(getChallenges: get, claimChallenge: claim),
      seed: () => const ChallengesSuccess(_board),
      setUp: () => when(() => claim('xp')).thenAnswer(
        (_) async => const Left(ServerFailure('Aún te falta un poco')),
      ),
      act: (b) => b.add(const ChallengeClaimed('xp')),
      expect: () => const [
        ChallengesSuccess(_board, claimingKey: 'xp'),
        ChallengesSuccess(_board, message: 'Aún te falta un poco'),
      ],
    );
  });
}
