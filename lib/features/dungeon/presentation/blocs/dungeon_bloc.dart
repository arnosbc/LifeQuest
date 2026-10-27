import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Left;

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_dungeon_cycle.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/complete_session_task.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/end_dungeon.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/get_dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/usecases/start_dungeon.dart';

part 'dungeon_event.dart';
part 'dungeon_state.dart';

/// Mazmorra: los ciclos se encadenan solos (ciclo → cobro → descanso →
/// ciclo). El tiempo se mide con marcas de hora, no restando segundos.
class DungeonBloc extends Bloc<DungeonEvent, DungeonState> {
  DungeonBloc({
    required this._getBoard,
    required this._start,
    required this._completeCycle,
    required this._completeTask,
    required this._end,
    DateTime Function()? clock,
    Stream<void> Function()? ticker,
  }) : _clock = clock ?? DateTime.now,
       super(const DungeonInitial()) {
    on<DungeonRequested>(_onRequested, transformer: droppable());
    on<DungeonStarted>(_onStarted, transformer: droppable());
    on<DungeonTicked>(_onTicked, transformer: droppable());
    on<DungeonPauseToggled>(_onPauseToggled);
    on<DungeonBreakSkipped>(_onBreakSkipped);
    on<DungeonTaskSelected>(_onTaskSelected);
    on<DungeonTaskCompleted>(_onTaskCompleted, transformer: droppable());
    on<DungeonEnded>(_onEnded, transformer: droppable());
    on<DungeonSummaryDismissed>(_onSummaryDismissed);
    _ticks = (ticker ?? _everySecond)().listen(
      (_) => add(const DungeonTicked()),
    );
  }

  final GetDungeonBoard _getBoard;
  final StartDungeon _start;
  final CompleteDungeonCycle _completeCycle;
  final CompleteSessionTask _completeTask;
  final EndDungeon _end;
  final DateTime Function() _clock;
  late final StreamSubscription<void> _ticks;

  static Stream<void> _everySecond() =>
      Stream<void>.periodic(const Duration(seconds: 1));

  @override
  Future<void> close() async {
    await _ticks.cancel();
    return super.close();
  }

  /// Estado al cargar un tablero. Con sesión abierta se empieza un ciclo
  /// completo: el avance local de un ciclo a medias no se guarda.
  DungeonReady _fresh(DungeonBoard board, {DungeonSummary? summary}) {
    final now = _clock();
    final session = board.session;
    if (session == null) {
      return DungeonReady(
        board: board,
        phase: DungeonPhase.setup,
        now: now,
        summary: summary,
      );
    }
    final done = session.cyclesDone >= session.maxCycles;
    return DungeonReady(
      board: board,
      phase: done ? DungeonPhase.done : DungeonPhase.focus,
      now: now,
      phaseEndsAt: done
          ? null
          : now.add(Duration(minutes: session.cycleMinutes)),
      currentTaskId: _nextTask(session, null),
    );
  }

  /// Mantiene la misión elegida si sigue abierta; si no, la primera abierta.
  static String? _nextTask(DungeonSession session, String? current) {
    final open = session.tasks.where((t) => !t.done);
    if (open.any((t) => t.id == current)) return current;
    return open.isEmpty ? session.tasks.firstOrNull?.id : open.first.id;
  }

  Future<void> _onRequested(
    DungeonRequested event,
    Emitter<DungeonState> emit,
  ) async {
    final current = state;
    if (current is! DungeonReady) emit(const DungeonLoading());
    final result = await _getBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is DungeonReady
            ? current.copyWith(message: failure.message)
            : DungeonFailure(failure.message),
        (board) => _refreshed(board),
      ),
    );
  }

  /// Refrescar la misma sesión conserva el cronómetro; si cambió, empieza de cero.
  DungeonState _refreshed(DungeonBoard board) {
    final latest = state;
    final session = board.session;
    if (latest is DungeonReady &&
        session != null &&
        latest.board.session?.id == session.id) {
      return latest.copyWith(
        board: board,
        currentTaskId: () => _nextTask(session, latest.currentTaskId),
      );
    }
    return _fresh(board);
  }

  Future<void> _onStarted(
    DungeonStarted event,
    Emitter<DungeonState> emit,
  ) async {
    final current = state;
    if (current is! DungeonReady || current.busy) return;
    emit(current.copyWith(busy: true));
    final started = await _start(
      StartDungeonParams(
        totalMinutes: event.totalMinutes,
        cycleMinutes: event.cycleMinutes,
        taskIds: event.taskIds,
      ),
    );
    if (started case Left(value: final failure)) {
      emit(current.copyWith(busy: false, message: failure.message));
      return;
    }
    final board = await _getBoard(const NoParams());
    emit(
      board.match(
        (failure) => current.copyWith(busy: false, message: failure.message),
        (b) => _fresh(
          b,
        ).copyWith(message: '¡Entraste a la Mazmorra! A por el primer ciclo.'),
      ),
    );
  }

  Future<void> _onTicked(
    DungeonTicked event,
    Emitter<DungeonState> emit,
  ) async {
    final current = state;
    if (current is! DungeonReady) return;
    final now = _clock();
    final ended =
        !current.paused &&
        !current.busy &&
        current.phaseEndsAt != null &&
        !now.isBefore(current.phaseEndsAt!);
    if (!ended) {
      if (current.phase == DungeonPhase.focus ||
          current.phase == DungeonPhase.rest) {
        emit(current.copyWith(now: now));
      }
      return;
    }
    final session = current.board.session!;
    if (current.phase == DungeonPhase.rest) {
      emit(
        current.copyWith(
          now: now,
          phase: DungeonPhase.focus,
          phaseEndsAt: () => now.add(Duration(minutes: session.cycleMinutes)),
          message: 'Descanso terminado. ¡Siguiente mazmorra!',
        ),
      );
      return;
    }
    await _claimCycle(current.copyWith(now: now), emit);
  }

  /// Cobra el ciclo (el servidor paga) y pasa al descanso o al final.
  Future<void> _claimCycle(
    DungeonReady current,
    Emitter<DungeonState> emit,
  ) async {
    final session = current.board.session!;
    final taskId = current.currentTaskId;
    if (taskId == null) return;
    emit(current.copyWith(busy: true));
    final claimed = await _completeCycle(
      CompleteDungeonCycleParams(sessionId: session.id, taskId: taskId),
    );
    final now = _clock();
    if (claimed case Left(value: final failure)) {
      // Se reintenta en 30 s (p. ej. sin conexión).
      emit(
        current.copyWith(
          now: now,
          busy: false,
          phaseEndsAt: () => now.add(const Duration(seconds: 30)),
          message: failure.message,
        ),
      );
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    final board = reloaded.getOrElse((_) => current.board);
    final s = board.session ?? session;
    final cycles = board.session == null
        ? session.cyclesDone + 1
        : s.cyclesDone;
    final done = cycles >= s.maxCycles;
    emit(
      current.copyWith(
        board: board,
        now: now,
        busy: false,
        phase: done ? DungeonPhase.done : DungeonPhase.rest,
        phaseEndsAt: () => done ? null : now.add(board.breakAfter(cycles)),
        currentTaskId: () => _nextTask(s, taskId),
        message: done
            ? '¡Último ciclo superado! Termina la sesión para ver tu botín.'
            : '¡Mazmorra superada! Toma un descanso.',
      ),
    );
  }

  void _onPauseToggled(DungeonPauseToggled event, Emitter<DungeonState> emit) {
    final current = state;
    if (current is! DungeonReady ||
        (current.phase != DungeonPhase.focus &&
            current.phase != DungeonPhase.rest)) {
      return;
    }
    final now = _clock();
    if (current.pausedLeft case final left?) {
      emit(
        current.copyWith(
          now: now,
          pausedLeft: () => null,
          phaseEndsAt: () => now.add(left),
        ),
      );
    } else {
      emit(
        current.copyWith(
          now: now,
          pausedLeft: () => current.copyWith(now: now).remaining,
          phaseEndsAt: () => null,
        ),
      );
    }
  }

  void _onBreakSkipped(DungeonBreakSkipped event, Emitter<DungeonState> emit) {
    final current = state;
    if (current is! DungeonReady || current.phase != DungeonPhase.rest) return;
    final now = _clock();
    emit(
      current.copyWith(
        now: now,
        phase: DungeonPhase.focus,
        pausedLeft: () => null,
        phaseEndsAt: () =>
            now.add(Duration(minutes: current.board.session!.cycleMinutes)),
      ),
    );
  }

  void _onTaskSelected(DungeonTaskSelected event, Emitter<DungeonState> emit) {
    final current = state;
    if (current is DungeonReady) {
      emit(current.copyWith(currentTaskId: () => event.taskId));
    }
  }

  Future<void> _onTaskCompleted(
    DungeonTaskCompleted event,
    Emitter<DungeonState> emit,
  ) async {
    final current = state;
    if (current is! DungeonReady || current.busy) return;
    emit(current.copyWith(busy: true));
    final completed = await _completeTask(event.taskId);
    if (completed case Left(value: final failure)) {
      emit(_latest(current).copyWith(busy: false, message: failure.message));
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    final latest = _latest(current);
    final board = reloaded.getOrElse((_) => latest.board);
    emit(
      latest.copyWith(
        board: board,
        busy: false,
        currentTaskId: () => board.session == null
            ? latest.currentTaskId
            : _nextTask(board.session!, latest.currentTaskId),
        message: '¡Misión completada! Tu héroe se hace más fuerte.',
      ),
    );
  }

  /// El estado actual si sigue listo (los tics lo avanzan mientras esperamos).
  DungeonReady _latest(DungeonReady fallback) =>
      state is DungeonReady ? state as DungeonReady : fallback;

  Future<void> _onEnded(DungeonEnded event, Emitter<DungeonState> emit) async {
    final current = state;
    final session = current is DungeonReady ? current.board.session : null;
    if (current is! DungeonReady || session == null || current.busy) return;
    emit(current.copyWith(busy: true));
    final ended = await _end(session.id);
    if (ended case Left(value: final failure)) {
      emit(_latest(current).copyWith(busy: false, message: failure.message));
      return;
    }
    final summary = ended.getRight().toNullable();
    final reloaded = await _getBoard(const NoParams());
    emit(
      _fresh(
        reloaded.getOrElse(
          (_) => DungeonBoard(candidates: current.board.candidates),
        ),
        summary: summary,
      ),
    );
  }

  void _onSummaryDismissed(
    DungeonSummaryDismissed event,
    Emitter<DungeonState> emit,
  ) {
    final current = state;
    if (current is DungeonReady) emit(current.copyWith());
  }
}
