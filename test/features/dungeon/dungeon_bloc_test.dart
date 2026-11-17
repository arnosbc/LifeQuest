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
  late MockAddSessionTask addTask;
  late MockToggleSessionStep toggleStep;
  late MockCompleteSessionHabit completeHabit;
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
    addTask = MockAddSessionTask();
    toggleStep = MockToggleSessionStep();
    completeHabit = MockCompleteSessionHabit();
    now = DateTime(2026, 10, 25, 9);
  });

  DungeonBloc build() => DungeonBloc(
    getBoard: getBoard,
    start: start,
    completeCycle: completeCycle,
    completeTask: completeTask,
    end: end,
    addTask: addTask,
    toggleStep: toggleStep,
    completeHabit: completeHabit,
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

  // «Empezar en Foco» con una sesión ya abierta: la tarea se suma y queda elegida.
  blocTest<DungeonBloc, DungeonState>(
    'con sesión abierta, la tarea tocada se suma a la sesión y queda elegida',
    setUp: () {
      const t3 = DungeonTask(id: 't3', title: 'Leer');
      final withT3 = DungeonBoard(
        candidates: const [t3],
        session: DungeonSession(
          id: 's1',
          totalMinutes: 60,
          cycleMinutes: 25,
          tasks: const [_t1, _t2, t3],
        ),
      );
      var calls = 0;
      when(() => getBoard(any())).thenAnswer(
        (_) async => Right(
          calls++ == 0
              ? DungeonBoard(candidates: const [t3], session: _board().session)
              : withT3,
        ),
      );
      when(() => addTask(any())).thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (bloc) => bloc.add(const DungeonRequested(taskId: 't3')),
    skip: 1,
    expect: () => [
      isA<DungeonReady>()
          .having((s) => s.currentTaskId, 'tarea elegida', 't3')
          .having((s) => s.board.session!.tasks.length, 'tareas', 3),
    ],
    verify: (_) => verify(
      () => addTask(
        const CompleteDungeonCycleParams(sessionId: 's1', taskId: 't3'),
      ),
    ).called(1),
  );

  blocTest<DungeonBloc, DungeonState>(
    'una tarea ya cerrada (fuera de candidatas) no se suma a la sesión',
    setUp: () => givenBoard(_board()),
    build: build,
    act: (bloc) => bloc.add(const DungeonRequested(taskId: 'vieja')),
    verify: (_) => verifyNever(() => addTask(any())),
  );

  blocTest<DungeonBloc, DungeonState>(
    'completar una tarea dice lo ganado y el total de la sesión',
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
          .having((s) => s.currentTaskId, 'siguiente tarea', 't2')
          .having((s) => s.board.session!.missionsDone, 'tareas', 1)
          .having(
            (s) => s.message,
            'aviso',
            '¡Tarea completada! +25 XP · +8 Monedas. '
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
      focus(_board()).copyWith(
        message: 'Has iniciado el Modo Foco. Vamos con el primer bloque.',
      ),
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
        message: '¡Bloque completado! Toma un descanso.',
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
        message: '¡Bloque completado! Toma un descanso.',
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
        message: '¡Bloque completado! Termina la sesión para ver el resumen.',
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

  // ---- Foco unificado (068) ----
  const habit = DungeonTask(id: 'h1', title: 'Leer', isHabit: true);
  DungeonBoard withHabit({bool done = false}) => DungeonBoard(
    session: DungeonSession(
      id: 's1',
      totalMinutes: 60,
      cycleMinutes: 25,
      tasks: const [_t1],
      habits: [DungeonTask(id: 'h1', title: 'Leer', isHabit: true, done: done)],
    ),
  );

  blocTest<DungeonBloc, DungeonState>(
    'paso hecho en Foco: lo marca, relee y avisa',
    setUp: () {
      when(() => toggleStep('p1')).thenAnswer((_) async => const Right(false));
      givenBoard(_board());
    },
    build: build,
    seed: () => focus(_board()),
    act: (bloc) => bloc.add(const DungeonStepDone('p1')),
    expect: () => [
      focus(_board()).copyWith(busy: true),
      focus(_board()).copyWith(message: '¡Paso hecho! Sigue con el siguiente.'),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'el último paso completa la tarea y lo dice',
    setUp: () {
      when(() => toggleStep('p9')).thenAnswer((_) async => const Right(true));
      givenBoard(_board());
    },
    build: build,
    seed: () => focus(_board()),
    act: (bloc) => bloc.add(const DungeonStepDone('p9')),
    skip: 1,
    expect: () => [
      focus(_board()).copyWith(message: '¡Tarea completada! Era el último paso.'),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'si el servidor no deja marcar el paso, avisa sin perder la sesión',
    setUp: () =>
        when(() => toggleStep('p1')).thenAnswer((_) async => const Left(failure)),
    build: build,
    seed: () => focus(_board()),
    act: (bloc) => bloc.add(const DungeonStepDone('p1')),
    skip: 1,
    expect: () => [focus(_board()).copyWith(message: 'Sin conexión.')],
  );

  blocTest<DungeonBloc, DungeonState>(
    'hábito hecho en Foco: lo cumple y pasa a lo siguiente abierto',
    setUp: () {
      when(() => completeHabit('h1')).thenAnswer((_) async => const Right(unit));
      givenBoard(withHabit(done: true));
    },
    build: build,
    seed: () => focus(withHabit()).copyWith(currentTaskId: () => 'h1'),
    act: (bloc) => bloc.add(const DungeonHabitDone('h1')),
    skip: 1,
    expect: () => [
      focus(withHabit(done: true)).copyWith(
        currentTaskId: () => 't1',
        message: '¡Hábito cumplido hoy! Tu racha sigue viva.',
      ),
    ],
  );

  blocTest<DungeonBloc, DungeonState>(
    'el bloque de un hábito se cobra como hábito',
    setUp: () {
      when(() => completeCycle(any())).thenAnswer((_) async => const Right(unit));
      givenBoard(withHabit());
    },
    build: build,
    seed: () => focus(withHabit()).copyWith(currentTaskId: () => habit.id),
    act: (bloc) {
      now = now.add(const Duration(minutes: 25));
      bloc.add(const DungeonTicked());
    },
    verify: (_) => verify(
      () => completeCycle(
        const CompleteDungeonCycleParams(
          sessionId: 's1',
          taskId: 'h1',
          isHabit: true,
        ),
      ),
    ).called(1),
  );

  blocTest<DungeonBloc, DungeonState>(
    'cumplido lo último de la sesión, se cierra sola y muestra el resumen',
    setUp: () {
      when(() => completeHabit('h1')).thenAnswer((_) async => const Right(unit));
      when(() => end('s1')).thenAnswer(
        (_) async => const Right(
          DungeonSummary(cycles: 0, xp: 25, coins: 8, minutes: 0, missions: 1),
        ),
      );
      var calls = 0;
      when(() => getBoard(any())).thenAnswer((_) async {
        calls++;
        // Primero la sesión con todo hecho; tras cerrar, sin sesión.
        return Right(
          calls == 1
              ? DungeonBoard(
                  session: DungeonSession(
                    id: 's1',
                    totalMinutes: 60,
                    cycleMinutes: 25,
                    tasks: const [
                      DungeonTask(id: 't1', title: 'Estudiar', done: true),
                    ],
                    habits: const [
                      DungeonTask(id: 'h1', title: 'Leer', isHabit: true, done: true),
                    ],
                  ),
                )
              : const DungeonBoard(),
        );
      });
    },
    build: build,
    seed: () => focus(withHabit()).copyWith(currentTaskId: () => 'h1'),
    act: (bloc) => bloc.add(const DungeonHabitDone('h1')),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      verify(() => end('s1')).called(1);
      final last = bloc.state as DungeonReady;
      expect(last.phase, DungeonPhase.setup);
      expect(last.summary?.xp, 25);
      expect(last.message, contains('¡Terminaste todo!'));
    },
  );

  blocTest<DungeonBloc, DungeonState>(
    'si aún queda algo pendiente, la sesión sigue abierta',
    setUp: () {
      when(() => toggleStep('p1')).thenAnswer((_) async => const Right(false));
      givenBoard(withHabit());
    },
    build: build,
    seed: () => focus(withHabit()),
    act: (bloc) => bloc.add(const DungeonStepDone('p1')),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verifyNever(() => end(any())),
  );
}
