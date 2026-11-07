import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/focus/data/models/focus_models.dart';
import 'package:proyecto_movil/features/focus/data/repositories/focus_repository_impl.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';

import '../../helpers/mocks.dart';

void main() {
  test('FocusBoardModel lee los descansos del jugador (RF-067)', () {
    final board = FocusBoardModel.fromJson({
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
    final fallback = FocusBoardModel.fromJson({}).toEntity();
    expect(fallback.breakAfter(4), const Duration(minutes: 15));
    expect(fallback.breakAfter(1), const Duration(minutes: 5));
  });

  test('FocusBoardModel convierte la sesión abierta', () {
    final board = FocusBoardModel.fromJson({
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
      const FocusTask(id: 't1', title: 'Estudiar', done: true, cycles: 1),
    );
    expect(board.candidates.single.id, 't2');
  });

  test('FocusBoardModel lee pasos, progreso y semana (037)', () {
    final board = FocusBoardModel.fromJson({
      'session': {
        'id': 's1',
        'total_minutes': 60,
        'cycle_minutes': 25,
        'tasks': [
          {
            'id': 't1',
            'title': 'Informe',
            'steps': [
              {'id': 'p1', 'title': 'Esquema', 'done': true},
              {'id': 'p2', 'title': 'Borrador', 'done': false},
            ],
          },
        ],
      },
      'progress': {'level': 3, 'current_xp': 40, 'xp_to_next_level': 520},
      'week': {'minutes': 90, 'prev_minutes': 60},
    }).toEntity();

    final task = board.session!.tasks.single;
    expect(task.stepsDone, 1);
    expect(task.nextStep, const FocusStep(id: 'p2', title: 'Borrador'));
    expect(
      board.progress,
      const FocusProgress(level: 3, currentXp: 40, xpToNextLevel: 520),
    );
    expect([board.weekMinutes, board.prevWeekMinutes], [90, 60]);
  });

  test('sin sesión queda null', () {
    expect(
      FocusBoardModel.fromJson({'session': null}).toEntity(),
      const FocusBoard(),
    );
  });

  group('FocusRepositoryImpl', () {
    late MockFocusRemoteDataSource remote;
    late FocusRepositoryImpl repository;

    setUp(() {
      remote = MockFocusRemoteDataSource();
      repository = FocusRepositoryImpl(remote);
    });

    test('end devuelve el resumen', () async {
      when(() => remote.end('s1')).thenAnswer(
        (_) async => const FocusSummaryModel({
          'cycles': 2,
          'xp': 20,
          'coins': 6,
          'minutes': 55,
        }),
      );
      expect(
        await repository.end('s1'),
        const Right(FocusSummary(cycles: 2, xp: 20, coins: 6, minutes: 55)),
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
            'Ya tienes una sesión de foco en curso. Desliza para retomarla.',
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
