import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_guide.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/complete_focus_cycle.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/start_focus.dart';
import 'package:proyecto_movil/features/focus/presentation/blocs/focus_bloc.dart';

import '../../helpers/mocks.dart';

const _t1 = FocusTask(id: 't1', title: 'Estudiar');
const _t2 = FocusTask(id: 't2', title: 'Escribir');

FocusBoard _board({
  int cycles = 0,
  int total = 60,
  bool t1Done = false,
  int shortBreak = 5,
}) => FocusBoard(
  shortBreakMinutes: shortBreak,
  session: FocusSession(
    id: 's1',
    totalMinutes: total,
    cycleMinutes: 25,
    cyclesDone: cycles,
    xpEarned: cycles * 10,
    tasks: [
      t1Done ? const FocusTask(id: 't1', title: 'Estudiar', done: true) : _t1,
      _t2,
    ],
  ),
);

const _setupBoard = FocusBoard(candidates: [_t1, _t2]);

void main() {
  late MockGetFocusBoard getBoard;
  late MockStartFocus start;
  late MockCompleteFocusCycle completeCycle;
  late MockCompleteSessionTask completeTask;
  late MockEndFocus end;
  late MockAddFocusStep addStep;
  late MockScheduleFocusTask schedule;
  late MockSaveStepProof saveProof;
  late MockSaveResumeNote saveResume;
  late MockCaptureDistraction captureDistraction;
  late MockGetRecallQuestions recallQuestions;
  late DateTime now;
  const failure = ServerFailure('Sin conexión.');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const StartFocusParams(totalMinutes: 60, cycleMinutes: 25, taskIds: []),
    );
    registerFallbackValue(
      const CompleteFocusCycleParams(sessionId: 's', taskId: 't'),
    );
    registerFallbackValue((taskId: 't', at: DateTime(2026)));
    registerFallbackValue((taskId: 't', title: ''));
    registerFallbackValue((taskId: 't', note: ''));
    registerFallbackValue((stepId: 's', proof: ResourceDraft.note('x')));
    registerFallbackValue(_t1);
  });

  setUp(() {
    getBoard = MockGetFocusBoard();
    start = MockStartFocus();
    completeCycle = MockCompleteFocusCycle();
    completeTask = MockCompleteSessionTask();
    end = MockEndFocus();
    addStep = MockAddFocusStep();
    schedule = MockScheduleFocusTask();
    saveProof = MockSaveStepProof();
    saveResume = MockSaveResumeNote();
    captureDistraction = MockCaptureDistraction();
    recallQuestions = MockGetRecallQuestions();
    now = DateTime(2026, 10, 25, 9);
  });

  FocusBloc build() => FocusBloc(
    getBoard: getBoard,
    start: start,
    completeCycle: completeCycle,
    completeTask: completeTask,
    addStep: addStep,
    schedule: schedule,
    end: end,
    saveProof: saveProof,
    saveResume: saveResume,
    captureDistraction: captureDistraction,
    recallQuestions: recallQuestions,
    clock: () => now,
    ticker: () => const Stream.empty(),
  );

  void givenBoard(FocusBoard board) =>
      when(() => getBoard(any())).thenAnswer((_) async => Right(board));

  FocusReady focus(FocusBoard board) => FocusReady(
    board: board,
    phase: FocusPhase.focus,
    now: now,
    phaseEndsAt: now.add(const Duration(minutes: 25)),
    currentTaskId: 't1',
  );

  blocTest<FocusBloc, FocusState>(
    'sin sesión abierta muestra la preparación de la mochila',
    setUp: () => givenBoard(_setupBoard),
    build: build,
    act: (bloc) => bloc.add(const FocusRequested()),
    expect: () => [
      const FocusLoading(),
      FocusReady(board: _setupBoard, phase: FocusPhase.setup, now: now),
    ],
  );

  blocTest<FocusBloc, FocusState>(
    'con sesión abierta empieza un ciclo completo en la primera tarea abierta',
    setUp: () => givenBoard(_board(t1Done: true)),
    build: build,
    act: (bloc) => bloc.add(const FocusRequested()),
    expect: () => [
      const FocusLoading(),
      focus(_board(t1Done: true)).copyWith(currentTaskId: () => 't2'),
    ],
  );

  blocTest<FocusBloc, FocusState>(
    'entrar crea la sesión y arranca el primer ciclo',
    setUp: () {
      when(() => start(any())).thenAnswer((_) async => const Right('s1'));
      givenBoard(_board());
    },
    build: build,
    seed: () =>
        FocusReady(board: _setupBoard, phase: FocusPhase.setup, now: now),
    act: (bloc) => bloc.add(
      const FocusStarted(
        totalMinutes: 60,
        cycleMinutes: 25,
        taskIds: ['t1'],
        intention: '  Esquema del informe ',
      ),
    ),
    expect: () => [
      FocusReady(
        board: _setupBoard,
        phase: FocusPhase.setup,
        now: now,
        busy: true,
      ),
      focus(_board()).copyWith(
        message: 'Foco en marcha. Primer ciclo.',
        intention: () => 'Esquema del informe',
      ),
    ],
  );

  blocTest<FocusBloc, FocusState>(
    'Empezar foco desde una tarea arranca 30 min una sola vez',
    setUp: () {
      when(() => start(any())).thenAnswer((_) async => const Right('s1'));
      givenBoard(_board());
    },
    build: build,
    seed: () =>
        FocusReady(board: _setupBoard, phase: FocusPhase.setup, now: now),
    act: (bloc) async {
      bloc.add(const FocusQuickStarted('t1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FocusQuickStarted('t1'));
    },
    skip: 1,
    expect: () => [
      focus(_board()).copyWith(message: 'Foco en marcha. Primer ciclo.'),
    ],
    verify: (_) => verify(
      () => start(
        const StartFocusParams(
          totalMinutes: 30,
          cycleMinutes: 25,
          taskIds: ['t1'],
        ),
      ),
    ).called(1),
  );

  blocTest<FocusBloc, FocusState>(
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
      bloc.add(const FocusTicked());
    },
    expect: () => [
      // El ciclo sembrado vencía justo ahora (now ya avanzó 25 min).
      focus(_board()).copyWith(now: now, busy: true, phaseEndsAt: () => now),
      FocusReady(
        board: _board(cycles: 1),
        phase: FocusPhase.rest,
        now: now,
        phaseEndsAt: now.add(const Duration(minutes: 5)),
        currentTaskId: 't1',
        message: 'Ciclo completado. Toma un descanso.',
      ),
    ],
    verify: (_) => verify(
      () => completeCycle(
        const CompleteFocusCycleParams(sessionId: 's1', taskId: 't1'),
      ),
    ).called(1),
  );

  blocTest<FocusBloc, FocusState>(
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
      bloc.add(const FocusTicked());
    },
    skip: 1,
    expect: () => [
      FocusReady(
        board: _board(cycles: 1, shortBreak: 8),
        phase: FocusPhase.rest,
        now: now,
        phaseEndsAt: now.add(const Duration(minutes: 8)),
        currentTaskId: 't1',
        message: 'Ciclo completado. Toma un descanso.',
      ),
    ],
  );

  blocTest<FocusBloc, FocusState>(
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
      bloc.add(const FocusTicked());
    },
    skip: 1,
    expect: () => [
      FocusReady(
        board: _board(cycles: 2),
        phase: FocusPhase.done,
        now: now,
        currentTaskId: 't1',
        message:
            '¡Último ciclo superado! Termina la sesión para ver tu resumen.',
      ),
    ],
  );

  blocTest<FocusBloc, FocusState>(
    'si el cobro falla, avisa y reintenta en 30 s',
    setUp: () => when(
      () => completeCycle(any()),
    ).thenAnswer((_) async => const Left(failure)),
    build: build,
    seed: () => focus(_board()),
    act: (bloc) {
      now = now.add(const Duration(minutes: 25));
      bloc.add(const FocusTicked());
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

  blocTest<FocusBloc, FocusState>(
    'pausar congela el tiempo y continuar lo retoma',
    build: build,
    seed: () => focus(_board()),
    act: (bloc) async {
      now = now.add(const Duration(minutes: 5));
      bloc.add(const FocusPauseToggled());
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(minutes: 10));
      bloc.add(const FocusPauseToggled());
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

  blocTest<FocusBloc, FocusState>(
    'terminar muestra el botín y vuelve a la preparación',
    setUp: () {
      when(() => end('s1')).thenAnswer(
        (_) async =>
            const Right(FocusSummary(cycles: 1, xp: 10, coins: 3, minutes: 26)),
      );
      givenBoard(_setupBoard);
    },
    build: build,
    seed: () => focus(_board(cycles: 1)),
    act: (bloc) => bloc.add(const FocusEnded()),
    skip: 1,
    expect: () => [
      FocusReady(
        board: _setupBoard,
        phase: FocusPhase.setup,
        now: now,
        // Con la historia: las tareas como quedaron y la semana.
        summary: FocusSummary(
          cycles: 1,
          xp: 10,
          coins: 3,
          minutes: 26,
          tasks: _board(cycles: 1).session!.tasks,
        ),
      ),
    ],
  );

  const before = FocusProgress(level: 2, currentXp: 20, xpToNextLevel: 280);
  const after = FocusProgress(level: 2, currentXp: 35, xpToNextLevel: 280);
  FocusBoard withProgress(FocusProgress p) =>
      FocusBoard(progress: p, session: _board().session);

  blocTest<FocusBloc, FocusState>(
    'marcar un paso lo completa y muestra la XP ganada',
    setUp: () {
      when(() => completeTask('p1')).thenAnswer((_) async => const Right(unit));
      givenBoard(withProgress(after));
    },
    build: build,
    seed: () => focus(withProgress(before)),
    act: (bloc) => bloc.add(const FocusStepCompleted('p1')),
    skip: 1,
    expect: () => [
      focus(withProgress(after)).copyWith(
        message: '¡Paso hecho!',
        gain: const FocusGain(xp: 15, levelUp: false, seq: 1),
        proofStepId: () => 'p1',
      ),
    ],
  );

  blocTest<FocusBloc, FocusState>(
    'el último paso abierto también completa la tarea',
    setUp: () {
      when(
        () => completeTask(any()),
      ).thenAnswer((_) async => const Right(unit));
      givenBoard(_board());
    },
    build: build,
    seed: () => focus(
      const FocusBoard(
        session: FocusSession(
          id: 's1',
          totalMinutes: 60,
          cycleMinutes: 25,
          tasks: [
            FocusTask(
              id: 't1',
              title: 'Estudiar',
              steps: [
                FocusStep(id: 's1', title: 'Leer', done: true),
                FocusStep(id: 's2', title: 'Resumir'),
              ],
            ),
          ],
        ),
      ),
    ),
    act: (bloc) => bloc.add(const FocusStepCompleted('s2')),
    verify: (_) {
      verify(() => completeTask('s2')).called(1);
      verify(() => completeTask('t1')).called(1);
    },
  );

  blocTest<FocusBloc, FocusState>(
    'añadir un paso lo guarda y recarga la tarea',
    setUp: () {
      when(() => addStep(any())).thenAnswer((_) async => const Right(unit));
      givenBoard(_board());
    },
    build: build,
    seed: () => focus(_board()),
    act: (bloc) =>
        bloc.add(const FocusStepAdded(taskId: 't1', title: 'Esquema')),
    skip: 1,
    expect: () => [focus(_board()).copyWith(message: 'Paso añadido.')],
    verify: (_) =>
        verify(() => addStep((taskId: 't1', title: 'Esquema'))).called(1),
  );

  blocTest<FocusBloc, FocusState>(
    'los pasos del asistente se guardan todos y recarga una vez',
    setUp: () {
      when(() => addStep(any())).thenAnswer((_) async => const Right(unit));
      givenBoard(_board());
    },
    build: build,
    seed: () => focus(_board()),
    act: (bloc) => bloc.add(
      const FocusStepsAdded(taskId: 't1', titles: ['Esquema', 'Borrador']),
    ),
    skip: 1,
    expect: () => [focus(_board()).copyWith(message: '2 pasos listos.')],
    verify: (_) {
      verify(() => addStep((taskId: 't1', title: 'Esquema'))).called(1);
      verify(() => addStep((taskId: 't1', title: 'Borrador'))).called(1);
    },
  );

  blocTest<FocusBloc, FocusState>(
    'la meta del ciclo se cambia y se borra si queda vacía',
    build: build,
    seed: () => focus(_board()),
    act: (bloc) async {
      bloc.add(const FocusIntentionChanged('Terminar la intro'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FocusIntentionChanged('   '));
    },
    expect: () => [
      focus(_board()).copyWith(intention: () => 'Terminar la intro'),
      focus(_board()),
    ],
  );

  const summary = FocusSummary(
    cycles: 1,
    xp: 10,
    coins: 3,
    minutes: 26,
    tasks: [_t1],
  );
  final tomorrow = DateTime(2026, 10, 26, 9);

  blocTest<FocusBloc, FocusState>(
    'desde el resumen agenda lo que sigue sin perder el resumen',
    setUp: () =>
        when(() => schedule(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => FocusReady(
      board: _setupBoard,
      phase: FocusPhase.setup,
      now: now,
      summary: summary,
    ),
    act: (bloc) => bloc.add(FocusNextScheduled(taskId: 't1', at: tomorrow)),
    skip: 1,
    expect: () => [
      FocusReady(
        board: _setupBoard,
        phase: FocusPhase.setup,
        now: now,
        summary: summary,
        nextScheduledAt: tomorrow,
        message: 'Listo, quedó en tu agenda.',
      ),
    ],
  );

  test('gainSince cuenta la XP aunque suba de nivel', () {
    expect(after.gainSince(before), 15);
    const up = FocusProgress(level: 3, currentXp: 5, xpToNextLevel: 520);
    expect(up.gainSince(before), 260 + 5);
  });

  test('el resumen propone la primera tarea sin terminar', () {
    expect(summary.next, _t1);
    expect(
      const FocusSummary(
        cycles: 0,
        xp: 0,
        coins: 0,
        minutes: 0,
        tasks: [FocusTask(id: 'x', title: 'Hecha', done: true)],
      ).next,
      isNull,
    );
  });

  test('la guía del descanso rota y distingue el largo', () {
    expect(
      FocusGuide.breakTip(1, long: false),
      isNot(FocusGuide.breakTip(2, long: false)),
    );
    expect(FocusGuide.breakTip(4, long: true), isNotEmpty);
  });

  group('Foco que deja algo', () {
    const step = FocusStep(id: 'p1', title: 'Leer el tema 3');
    const withStep = FocusTask(id: 't1', title: 'Estudiar', steps: [step]);
    final board = FocusBoard(
      session: const FocusSession(
        id: 's1',
        totalMinutes: 60,
        cycleMinutes: 25,
        tasks: [withStep, _t2],
      ),
    );

    test('recallNotes junta Dónde lo dejé y las pruebas de los pasos hechos', () {
      const t = FocusTask(
        id: 't',
        title: 'Estudiar',
        resumeNote: 'Sigo en el 6',
        steps: [
          FocusStep(id: 'a', title: 'Ej. 1-5', done: true, proof: 'Me trabé en el 4'),
          FocusStep(id: 'b', title: 'Ej. 6-10'),
        ],
      );
      expect(t.recallNotes, ['Sigo en el 6', 'Ej. 1-5: Me trabé en el 4']);
      expect(t.resumeSuggestion, 'Sigue: Ej. 6-10');
      expect(_t1.recallNotes, isEmpty);
      expect(_t1.resumeSuggestion, '');
    });

    blocTest<FocusBloc, FocusState>(
      'al marcar un paso ofrece dejar prueba; «Ahora no» la quita',
      setUp: () {
        givenBoard(board);
        when(() => completeTask(any())).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      seed: () => focus(board),
      act: (bloc) async {
        bloc.add(const FocusStepCompleted('p1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FocusStepProofSkipped());
      },
      skip: 1,
      expect: () => [
        isA<FocusReady>().having((s) => s.proofStepId, 'proof', 'p1'),
        isA<FocusReady>().having((s) => s.proofStepId, 'proof', null),
      ],
    );

    blocTest<FocusBloc, FocusState>(
      'la prueba se guarda como recurso del paso',
      setUp: () {
        givenBoard(board);
        when(() => saveProof(any())).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      seed: () => focus(board).copyWith(proofStepId: () => 'p1'),
      act: (bloc) => bloc.add(
        FocusStepProofSaved(stepId: 'p1', proof: ResourceDraft.note('Hecho')),
      ),
      verify: (bloc) {
        verify(() => saveProof((stepId: 'p1', proof: ResourceDraft.note('Hecho')))).called(1);
        expect((bloc.state as FocusReady).proofStepId, isNull);
      },
    );

    blocTest<FocusBloc, FocusState>(
      'una distracción va a la Bandeja y se cuenta',
      setUp: () => when(
        () => captureDistraction(any()),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => focus(board),
      act: (bloc) => bloc.add(const FocusDistractionCaptured('Pagar la luz')),
      expect: () => [
        isA<FocusReady>()
            .having((s) => s.distractions, 'distractions', 1)
            .having((s) => s.message, 'message', 'A la Bandeja. Sigue con lo tuyo.'),
      ],
    );

    blocTest<FocusBloc, FocusState>(
      'Dónde lo dejé se guarda sin perder el resumen',
      setUp: () => when(
        () => saveResume(any()),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => FocusReady(
        board: _setupBoard,
        phase: FocusPhase.setup,
        now: now,
        summary: const FocusSummary(cycles: 1, xp: 10, coins: 0, minutes: 25),
      ),
      act: (bloc) =>
          bloc.add(const FocusResumeNoteSaved(taskId: 't1', note: 'Sigo en el 6')),
      expect: () => [
        isA<FocusReady>()
            .having((s) => s.resumeSaved, 'saved', {'t1'})
            .having((s) => s.summary, 'summary', isNotNull),
      ],
    );

    blocTest<FocusBloc, FocusState>(
      'el repaso trae preguntas de la IA para la tarea',
      setUp: () => when(() => recallQuestions(any())).thenAnswer(
        (_) async => const Right(['¿Qué falló en el 4?']),
      ),
      build: build,
      seed: () => focus(board),
      act: (bloc) => bloc.add(const FocusRecallRequested('t1')),
      expect: () => [
        isA<FocusReady>().having((s) => s.recallAsking, 'asking', 't1'),
        isA<FocusReady>()
            .having((s) => s.recallAsking, 'asking', null)
            .having((s) => s.recall['t1'], 'questions', ['¿Qué falló en el 4?']),
      ],
    );
  });
}
