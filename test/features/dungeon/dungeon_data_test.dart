import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/dungeon/data/models/dungeon_models.dart';
import 'package:proyecto_movil/features/dungeon/data/repositories/dungeon_repository_impl.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';

import '../../helpers/mocks.dart';

void main() {
  test('DungeonBoardModel lee los descansos del jugador (RF-067)', () {
    final board = DungeonBoardModel.fromJson({
      'breaks': {
        'short_minutes': 10,
        'long_minutes': 30,
        'long_every_n_cycles': 3,
      },
    }).toEntity();
    expect(
      [
        board.shortBreakMinutes,
        board.longBreakMinutes,
        board.longBreakEveryNCycles,
      ],
      [10, 30, 3],
    );
    // Largo justo tras cada 3 ciclos; corto en los demás.
    expect(
      [
        for (final c in [1, 2, 3, 4, 6]) board.breakAfter(c).inMinutes,
      ],
      [10, 10, 30, 10, 30],
    );
    // Sin `breaks` (servidor sin 017): los de RF-067 por defecto.
    final fallback = DungeonBoardModel.fromJson({}).toEntity();
    expect(fallback.breakAfter(4), const Duration(minutes: 15));
    expect(fallback.breakAfter(1), const Duration(minutes: 5));
  });

  test('DungeonBoardModel convierte la sesión abierta', () {
    final board = DungeonBoardModel.fromJson({
      'session': {
        'id': 's1',
        'total_minutes': 90,
        'cycle_minutes': 30,
        'cycles_done': 1,
        'xp_earned': 10,
        'coins_earned': 3,
        'tasks': [
          {'id': 't1', 'title': 'Estudiar', 'done': true, 'cycles': 1},
        ],
      },
      'candidates': [
        {'id': 't2', 'title': 'Escribir', 'bucket': 'high'},
      ],
      'max_tasks': 5,
      'cycle_xp': 10,
    }).toEntity();

    final s = board.session!;
    expect(
      [s.totalMinutes, s.cycleMinutes, s.maxCycles, s.cyclesDone],
      [90, 30, 3, 1],
    );
    expect([s.xpEarned, s.coinsEarned], [10, 3]);
    expect(
      s.tasks.single,
      const DungeonTask(id: 't1', title: 'Estudiar', done: true, cycles: 1),
    );
    expect(board.candidates.single.id, 't2');
  });

  test('sin sesión queda null', () {
    expect(
      DungeonBoardModel.fromJson({'session': null}).toEntity(),
      const DungeonBoard(),
    );
  });

  group('DungeonRepositoryImpl', () {
    late MockDungeonRemoteDataSource remote;
    late DungeonRepositoryImpl repository;

    setUp(() {
      remote = MockDungeonRemoteDataSource();
      repository = DungeonRepositoryImpl(remote);
    });

    test('end devuelve el resumen', () async {
      when(() => remote.end('s1')).thenAnswer(
        (_) async => const DungeonSummaryModel({
          'cycles': 2,
          'xp': 20,
          'coins': 6,
          'minutes': 55,
        }),
      );
      expect(
        await repository.end('s1'),
        const Right(DungeonSummary(cycles: 2, xp: 20, coins: 6, minutes: 55)),
      );
    });

    test('traduce los motivos del servidor', () async {
      when(
        () => remote.start(totalMinutes: 60, cycleMinutes: 25, taskIds: ['t1']),
      ).thenThrow(const ServerException(code: 'session_already_open'));
      expect(
        await repository.start(
          totalMinutes: 60,
          cycleMinutes: 25,
          taskIds: ['t1'],
        ),
        const Left(
          ServerFailure(
            'Ya tienes una Mazmorra en curso. Desliza para retomarla.',
          ),
        ),
      );
    });

    test('sin conexión devuelve NetworkFailure', () async {
      when(
        () => remote.completeCycle(sessionId: 's1', taskId: 't1'),
      ).thenThrow(const NetworkException());
      expect(
        (await repository.completeCycle(
          sessionId: 's1',
          taskId: 't1',
        )).getLeft().toNullable(),
        isA<NetworkFailure>(),
      );
    });
  });
}
