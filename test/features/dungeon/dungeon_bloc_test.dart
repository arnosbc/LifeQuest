import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_dungeon_cycle.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/start_dungeon.dart';
import 'package:proyecto_movil/features/dungeon/presentation/blocs/dungeon_bloc.dart';

import '../../helpers/mocks.dart';

const _t1 = DungeonTask(id: 't1', title: 'Estudiar');
const _t2 = DungeonTask(id: 't2', title: 'Escribir');

DungeonBoard _board({
  int cycles = 0,
  int total = 60,
  bool t1Done = false,
  int shortBreak = 5,
}) => DungeonBoard(
  shortBreakMinutes: shortBreak,
  session: DungeonSession(
    id: 's1',
    totalMinutes: total,
    cycleMinutes: 25,
    cyclesDone: cycles,
    xpEarned: cycles * 10,
    tasks: [
      t1Done ? const DungeonTask(id: 't1', title: 'Estudiar', done: true) : _t1,
      _t2,
    ],
  ),
);

const _setupBoard = DungeonBoard(candidates: [_t1, _t2]);

void main() {
  late MockGetDungeonBoard getBoard;
  late MockStartDungeon start;
  late MockCompleteDungeonCycle completeCycle;
  late MockCompleteSessionTask completeTask;
  late MockEndDungeon end;
  late DateTime now;
  const failure = ServerFailure('Sin conexión.');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const StartDungeonParams(totalMinutes: 60, cycleMinutes: 25, taskIds: []),
    );
    registerFallbackValue(
      const CompleteDungeonCycleParams(sessionId: 's', taskId: 't'),
    );
  });

  setUp(() {
    getBoard = MockGetDungeonBoard();
    start = MockStartDungeon();
    completeCycle = MockCompleteDungeonCycle();
    completeTask = MockCompleteSessionTask();
    end = MockEndDungeon();
    now = DateTime(2026, 10, 25, 9);
  });

  DungeonBloc build() => DungeonBloc(
    getBoard: getBoard,
    start: start,
    completeCycle: completeCycle,
    completeTask: completeTask,
    end: end,
    clock: () => now,
    ticker: () => const Stream.empty(),
  );

  void givenBoard(DungeonBoard board) =>
      when(() => getBoard(any())).thenAnswer((_) async => Right(board));

  DungeonReady focus(DungeonBoard board) => DungeonReady(
    board: board,
    phase: DungeonPhase.focus,
    now: now,
    phaseEndsAt: now.add(const Duration(minutes: 25)),
    currentTaskId: 't1',
  );

  blocTest<DungeonBloc, DungeonState>(
    'completar una misión dice lo ganado y el total de la sesión',
    setUp: () {
      when(
        () => completeTask('t1'),
      ).thenAnswer((_) async => const Right(DungeonReward(xp: 25, coins: 8)));
      givenBoard(
        DungeonBoard(
          session: DungeonSession(
            id: 's1',
            totalMinutes: 60,
            cycleMinutes: 25,
            cyclesDone: 1,
            xpEarned: 35,
            coinsEarned: 11,
            missionsDone: 1,
            tasks: const [
              DungeonTask(id: 't1', title: 'Estudiar', done: true),
              _t2,
            ],
          ),
        ),
      );
    },
    build: build,
    seed: () => focus(_board(cycles: 1)),
    act: (bloc) => bloc.add(const DungeonTaskCompleted('t1')),
    skip: 1,
    expect: () => [
      isA<DungeonReady>()
          .having((s) => s.currentTaskId, 'siguiente misión', 't2')
          .having((s) => s.board.session!.missionsDone, 'misiones', 1)
          .having(
            (s) => s.message,
            'aviso',
            '¡Misión completada! +25 XP · +8 Monedas. '
                'En esta sesión llevas 35 XP y 11 Monedas.',
          ),
    ],
  );

  test('el tiempo efectivo cuenta solo los ciclos cobrados', () {
    expect(_board(cycles: 2).session!.focusMinutes, 50);
  });

  blocTest<DungeonBloc, DungeonState>(
    'sin sesión abierta muestra la preparación de la mochila',
    setUp: () => givenBoard(_setupBoard),
    build: build,
    act: (bloc) => bloc.add(const DungeonRequested()),
    expect: () => [
      const DungeonLoading(),
      DungeonReady(board: _setupBoard, phase: DungeonPhase.setup, now: now),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'con sesión abierta empieza un ciclo completo en la primera misión abierta',
    setUp: () => givenBoard(_board(t1Done: true)),
    build: build,
    act: (bloc) => bloc.add(const DungeonRequested()),
    expect: () => [
      const DungeonLoading(),
      focus(_board(t1Done: true)).copyWith(currentTaskId: () => 't2'),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'entrar crea la sesión y arranca el primer ciclo',
    setUp: () {
      when(() => start(any())).thenAnswer((_) async => const Right('s1'));
      givenBoard(_board());
    },
    build: build,
    seed: () =>
        DungeonReady(board: _setupBoard, phase: DungeonPhase.setup, now: now),
    act: (bloc) => bloc.add(
      const DungeonStarted(totalMinutes: 60, cycleMinutes: 25, taskIds: ['t1']),
    ),
    expect: () => [
      DungeonReady(
        board: _setupBoard,
        phase: DungeonPhase.setup,
        now: now,
        busy: true,
      ),
      focus(
        _board(),
      ).copyWith(message: '¡Entraste a la Mazmorra! A por el primer ciclo.'),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'al terminar el ciclo lo cobra y pasa al descanso corto',
    setUp: () {
      when(
        () => completeCycle(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(_board(cycles: 1));
    },
    build: build,
    seed: () => focus(_board()),
    act: (bloc) {
      now = now.add(const Duration(minutes: 25));
      bloc.add(const DungeonTicked());
    },
    expect: () => [
      // El ciclo sembrado vencía justo ahora (now ya avanzó 25 min).
      focus(_board()).copyWith(now: now, busy: true, phaseEndsAt: () => now),
      DungeonReady(
        board: _board(cycles: 1),
        phase: DungeonPhase.rest,
        now: now,
        phaseEndsAt: now.add(const Duration(minutes: 5)),
        currentTaskId: 't1',
        message: '¡Mazmorra superada! Toma un descanso.',
      ),
    ],
    verify: (_) => verify(
      () => completeCycle(
        const CompleteDungeonCycleParams(sessionId: 's1', taskId: 't1'),
      ),
    ).called(1),
  );

  blocTest<DungeonBloc, DungeonState>(
    'el descanso dura lo que el jugador eligió en Configuración',
    setUp: () {
      when(
        () => completeCycle(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(_board(cycles: 1, shortBreak: 8));
    },
    build: build,
    seed: () => focus(_board(shortBreak: 8)),
    act: (bloc) {
      now = now.add(const Duration(minutes: 25));
      bloc.add(const DungeonTicked());
    },
    skip: 1,
    expect: () => [
      DungeonReady(
        board: _board(cycles: 1, shortBreak: 8),
        phase: DungeonPhase.rest,
        now: now,
        phaseEndsAt: now.add(const Duration(minutes: 8)),
        currentTaskId: 't1',
        message: '¡Mazmorra superada! Toma un descanso.',
      ),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'el último ciclo deja la sesión lista para terminar',
    setUp: () {
      when(
        () => completeCycle(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(_board(cycles: 2));
    },
    build: build,
    seed: () => focus(_board(cycles: 1)),
    act: (bloc) {
      now = now.add(const Duration(minutes: 25));
      bloc.add(const DungeonTicked());
    },
    skip: 1,
    expect: () => [
      DungeonReady(
        board: _board(cycles: 2),
        phase: DungeonPhase.done,
        now: now,
        currentTaskId: 't1',
        message: '¡Último ciclo superado! Termina la sesión para ver tu botín.',
      ),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'si el cobro falla, avisa y reintenta en 30 s',
    setUp: () => when(
      () => completeCycle(any()),
    ).thenAnswer((_) async => const Left(failure)),
    build: build,
    seed: () => focus(_board()),
    act: (bloc) {
      now = now.add(const Duration(minutes: 25));
      bloc.add(const DungeonTicked());
    },
    skip: 1,
    expect: () => [
      focus(_board()).copyWith(
        now: now,
        phaseEndsAt: () => now.add(const Duration(seconds: 30)),
        message: failure.message,
      ),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'pausar congela el tiempo y continuar lo retoma',
    build: build,
    seed: () => focus(_board()),
    act: (bloc) async {
      now = now.add(const Duration(minutes: 5));
      bloc.add(const DungeonPauseToggled());
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(minutes: 10));
      bloc.add(const DungeonPauseToggled());
    },
    expect: () => [
      focus(_board()).copyWith(
        now: DateTime(2026, 10, 25, 9, 5),
        phaseEndsAt: () => null,
        pausedLeft: () => const Duration(minutes: 20),
      ),
      focus(_board()).copyWith(
        now: DateTime(2026, 10, 25, 9, 15),
        phaseEndsAt: () => DateTime(2026, 10, 25, 9, 35),
      ),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'terminar muestra el botín y vuelve a la preparación',
    setUp: () {
      when(() => end('s1')).thenAnswer(
        (_) async => const Right(
          DungeonSummary(cycles: 1, xp: 10, coins: 3, minutes: 26),
        ),
      );
      givenBoard(_setupBoard);
    },
    build: build,
    seed: () => focus(_board(cycles: 1)),
    act: (bloc) => bloc.add(const DungeonEnded()),
    skip: 1,
    expect: () => [
      DungeonReady(
        board: _setupBoard,
        phase: DungeonPhase.setup,
        now: now,
        summary: const DungeonSummary(cycles: 1, xp: 10, coins: 3, minutes: 26),
      ),
    ],
  );
}
