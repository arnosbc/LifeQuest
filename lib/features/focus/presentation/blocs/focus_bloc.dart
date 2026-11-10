import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Left;

import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/capture_distraction.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/get_recall_questions.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/save_resume_note.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/save_step_proof.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/add_focus_step.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/complete_focus_cycle.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/complete_session_task.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/end_focus.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/get_focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/schedule_focus_task.dart';
import 'package:proyecto_movil/features/focus/domain/usecases/start_focus.dart';

part 'focus_event.dart';
part 'focus_state.dart';

/// Foco: los ciclos se encadenan solos (ciclo → cobro → descanso →
/// ciclo). El tiempo se mide con marcas de hora, no restando segundos.
class FocusBloc extends Bloc<FocusEvent, FocusState> {
  FocusBloc({
    required this._getBoard,
    required this._start,
    required this._completeCycle,
    required this._completeTask,
    required this._addStep,
    required this._schedule,
    required this._end,
    required this._saveProof,
    required this._saveResume,
    required this._captureDistraction,
    required this._recallQuestions,
    DateTime Function()? clock,
    Stream<void> Function()? ticker,
  }) : _clock = clock ?? DateTime.now,
       super(const FocusInitial()) {
    on<FocusRequested>(_onRequested, transformer: droppable());
    on<FocusStarted>(_onStarted, transformer: droppable());
    on<FocusQuickStarted>(_onQuickStarted, transformer: droppable());
    on<FocusTicked>(_onTicked, transformer: droppable());
    on<FocusPauseToggled>(_onPauseToggled);
    on<FocusBreakSkipped>(_onBreakSkipped);
    on<FocusTaskSelected>(_onTaskSelected);
    on<FocusTaskCompleted>(
      (e, emit) => _completeAndReload(e.taskId, '¡Tarea completada!', emit),
      transformer: droppable(),
    );
    on<FocusStepCompleted>(_onStepCompleted, transformer: droppable());
    on<FocusStepAdded>(_onStepAdded, transformer: droppable());
    on<FocusStepsAdded>(_onStepsAdded, transformer: droppable());
    on<FocusIntentionChanged>(_onIntentionChanged);
    on<FocusNextScheduled>(_onNextScheduled, transformer: droppable());
    on<FocusEnded>(_onEnded, transformer: droppable());
    on<FocusSummaryDismissed>(_onSummaryDismissed);
    on<FocusStepProofSaved>(_onProofSaved, transformer: droppable());
    on<FocusStepProofSkipped>(
      (_, emit) => _update(emit, (s) => s.copyWith(proofStepId: () => null)),
    );
    on<FocusResumeNoteSaved>(_onResumeSaved, transformer: sequential());
    on<FocusDistractionCaptured>(_onDistraction, transformer: sequential());
    on<FocusRecallRequested>(_onRecall, transformer: droppable());
    on<FocusRecallDismissed>(
      (e, emit) => _update(
        emit,
        (s) => s.copyWith(recallDismissed: {...s.recallDismissed, e.taskId}),
      ),
    );
    _ticks = (ticker ?? _everySecond)().listen((_) => add(const FocusTicked()));
  }

  final GetFocusBoard _getBoard;
  final StartFocus _start;
  final CompleteFocusCycle _completeCycle;
  final CompleteSessionTask _completeTask;
  final AddFocusStep _addStep;
  final ScheduleFocusTask _schedule;
  final EndFocus _end;
  final SaveStepProof _saveProof;
  final SaveResumeNote _saveResume;
  final CaptureDistraction _captureDistraction;
  final GetRecallQuestions _recallQuestions;
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
  FocusReady _fresh(FocusBoard board, {FocusSummary? summary}) {
    final now = _clock();
    final session = board.session;
    if (session == null) {
      return FocusReady(
        board: board,
        phase: FocusPhase.setup,
        now: now,
        summary: summary,
      );
    }
    final done = session.cyclesDone >= session.maxCycles;
    return FocusReady(
      board: board,
      phase: done ? FocusPhase.done : FocusPhase.focus,
      now: now,
      phaseEndsAt: done
          ? null
          : now.add(Duration(minutes: session.cycleMinutes)),
      currentTaskId: _nextTask(session, null),
    );
  }

  /// Mantiene la tarea elegida si sigue abierta; si no, la primera abierta.
  static String? _nextTask(FocusSession session, String? current) {
    final open = session.tasks.where((t) => !t.done);
    if (open.any((t) => t.id == current)) return current;
    return open.isEmpty ? session.tasks.firstOrNull?.id : open.first.id;
  }

  Future<void> _onRequested(
    FocusRequested event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady) emit(const FocusLoading());
    final result = await _getBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is FocusReady
            ? current.copyWith(message: failure.message)
            : FocusFailure(failure.message),
        (board) => _refreshed(board),
      ),
    );
  }

  /// Refrescar la misma sesión conserva el cronómetro; si cambió, empieza de cero.
  FocusState _refreshed(FocusBoard board) {
    final latest = state;
    final session = board.session;
    if (latest is FocusReady &&
        session != null &&
        latest.board.session?.id == session.id) {
      return latest.copyWith(
        board: board,
        currentTaskId: () => _nextTask(session, latest.currentTaskId),
      );
    }
    return _fresh(board);
  }

  /// Un bloque de 30 min con un ciclo de 25 (la duración va en pasos de 30).
  static const quickTotal = 30;
  static const quickCycle = 25;

  /// Tareas ya arrancadas con un toque: volver a la pestaña no repite.
  final _quickStarted = <String>{};

  Future<void> _onQuickStarted(
    FocusQuickStarted event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady ||
        current.board.session != null ||
        !_quickStarted.add(event.taskId) ||
        !current.board.candidates.any((t) => t.id == event.taskId)) {
      return;
    }
    await _onStarted(
      FocusStarted(
        totalMinutes: quickTotal,
        cycleMinutes: quickCycle,
        taskIds: [event.taskId],
      ),
      emit,
    );
  }

  Future<void> _onStarted(FocusStarted event, Emitter<FocusState> emit) async {
    final current = state;
    if (current is! FocusReady || current.busy) return;
    emit(current.copyWith(busy: true));
    final started = await _start(
      StartFocusParams(
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
        (b) => _fresh(b).copyWith(
          message: 'Foco en marcha. Primer ciclo.',
          intention: () => _clean(event.intention),
        ),
      ),
    );
  }

  Future<void> _onTicked(FocusTicked event, Emitter<FocusState> emit) async {
    final current = state;
    if (current is! FocusReady) return;
    final now = _clock();
    final ended =
        !current.paused &&
        !current.busy &&
        current.phaseEndsAt != null &&
        !now.isBefore(current.phaseEndsAt!);
    if (!ended) {
      if (current.phase == FocusPhase.focus ||
          current.phase == FocusPhase.rest) {
        emit(current.copyWith(now: now));
      }
      return;
    }
    final session = current.board.session!;
    if (current.phase == FocusPhase.rest) {
      emit(
        current.copyWith(
          now: now,
          phase: FocusPhase.focus,
          phaseEndsAt: () => now.add(Duration(minutes: session.cycleMinutes)),
          message: 'Descanso terminado. Siguiente ciclo.',
        ),
      );
      return;
    }
    await _claimCycle(current.copyWith(now: now), emit);
  }

  /// Cobra el ciclo (el servidor paga) y pasa al descanso o al final.
  Future<void> _claimCycle(FocusReady current, Emitter<FocusState> emit) async {
    final session = current.board.session!;
    final taskId = current.currentTaskId;
    if (taskId == null) return;
    emit(current.copyWith(busy: true));
    final claimed = await _completeCycle(
      CompleteFocusCycleParams(sessionId: session.id, taskId: taskId),
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
        phase: done ? FocusPhase.done : FocusPhase.rest,
        phaseEndsAt: () => done ? null : now.add(board.breakAfter(cycles)),
        currentTaskId: () => _nextTask(s, taskId),
        gain: _gain(current, board),
        message: done
            ? '¡Último ciclo superado! Termina la sesión para ver tu resumen.'
            : 'Ciclo completado. Toma un descanso.',
      ),
    );
  }

  void _onPauseToggled(FocusPauseToggled event, Emitter<FocusState> emit) {
    final current = state;
    if (current is! FocusReady ||
        (current.phase != FocusPhase.focus &&
            current.phase != FocusPhase.rest)) {
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

  void _onBreakSkipped(FocusBreakSkipped event, Emitter<FocusState> emit) {
    final current = state;
    if (current is! FocusReady || current.phase != FocusPhase.rest) return;
    final now = _clock();
    emit(
      current.copyWith(
        now: now,
        phase: FocusPhase.focus,
        pausedLeft: () => null,
        phaseEndsAt: () =>
            now.add(Duration(minutes: current.board.session!.cycleMinutes)),
      ),
    );
  }

  void _onTaskSelected(FocusTaskSelected event, Emitter<FocusState> emit) {
    final current = state;
    if (current is FocusReady) {
      emit(current.copyWith(currentTaskId: () => event.taskId));
    }
  }

  /// Completa una tarea o un paso (misma RPC) y muestra la XP ganada.
  Future<void> _completeAndReload(
    String id,
    String message,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady || current.busy) return;
    emit(current.copyWith(busy: true));
    final completed = await _completeTask(id);
    if (completed case Left(value: final failure)) {
      emit(_latest(current).copyWith(busy: false, message: failure.message));
      return;
    }
    await _reload(current, message, emit);
  }

  /// Marca el paso y, si era el último abierto, también la tarea.
  Future<void> _onStepCompleted(
    FocusStepCompleted event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady || current.busy) return;
    final parent = current.board.session?.tasks
        .where(
          (t) =>
              !t.done &&
              t.steps.any((s) => s.id == event.stepId) &&
              t.steps.every((s) => s.done || s.id == event.stepId),
        )
        .firstOrNull;
    emit(current.copyWith(busy: true));
    for (final id in [event.stepId, ?parent?.id]) {
      if (await _completeTask(id) case Left(value: final failure)) {
        // El paso pudo entrar aunque la tarea no: se recarga para verlo.
        await _reload(current, failure.message, emit);
        return;
      }
    }
    // Se ofrece dejar prueba de lo hecho; es opcional y no frena.
    await _reload(
      current,
      parent == null ? '¡Paso hecho!' : '¡Último paso! Tarea completada.',
      emit,
      proofStepId: () => event.stepId,
    );
  }

  void _update(Emitter<FocusState> emit, FocusReady Function(FocusReady) f) {
    if (state case final FocusReady s) emit(f(s));
  }

  Future<void> _onProofSaved(
    FocusStepProofSaved event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady) return;
    emit(current.copyWith(busy: true));
    final saved = await _saveProof((stepId: event.stepId, proof: event.proof));
    if (saved case Left(value: final failure)) {
      emit(_latest(current).copyWith(busy: false, message: failure.message));
      return;
    }
    await _reload(
      current,
      'Guardado en el paso. Te servirá al repasar.',
      emit,
      proofStepId: () => null,
    );
  }

  Future<void> _onResumeSaved(
    FocusResumeNoteSaved event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady) return;
    final saved = await _saveResume((taskId: event.taskId, note: event.note));
    final latest = _latest(current);
    emit(
      saved.match(
        (f) => latest.copyWith(summary: latest.summary, message: f.message),
        (_) => latest.copyWith(
          summary: latest.summary,
          nextScheduledAt: latest.nextScheduledAt,
          resumeSaved: {...latest.resumeSaved, event.taskId},
          message: 'Listo. La próxima vez empiezas por ahí.',
        ),
      ),
    );
  }

  Future<void> _onDistraction(
    FocusDistractionCaptured event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady) return;
    final saved = await _captureDistraction(event.text);
    final latest = _latest(current);
    emit(
      saved.match(
        (f) => latest.copyWith(message: f.message),
        (_) => latest.copyWith(
          distractions: latest.distractions + 1,
          message: 'A la Bandeja. Sigue con lo tuyo.',
        ),
      ),
    );
  }

  Future<void> _onRecall(
    FocusRecallRequested event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady) return;
    final task = current.board.session?.tasks
        .where((t) => t.id == event.taskId)
        .firstOrNull;
    if (task == null) return;
    emit(current.copyWith(recallAsking: () => task.id));
    final result = await _recallQuestions(task);
    final latest = _latest(current).copyWith(recallAsking: () => null);
    emit(
      result.match(
        (f) => latest.copyWith(message: f.message),
        (qs) => latest.copyWith(recall: {...latest.recall, task.id: qs}),
      ),
    );
  }

  Future<void> _onStepAdded(
    FocusStepAdded event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady || current.busy) return;
    emit(current.copyWith(busy: true));
    final added = await _addStep((taskId: event.taskId, title: event.title));
    if (added case Left(value: final failure)) {
      emit(_latest(current).copyWith(busy: false, message: failure.message));
      return;
    }
    await _reload(current, 'Paso añadido.', emit);
  }

  Future<void> _onStepsAdded(
    FocusStepsAdded event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady || current.busy || event.titles.isEmpty) return;
    emit(current.copyWith(busy: true));
    for (final title in event.titles) {
      final added = await _addStep((taskId: event.taskId, title: title));
      if (added case Left(value: final failure)) {
        // Los que ya entraron se quedan: se recarga para mostrarlos.
        await _reload(current, failure.message, emit);
        return;
      }
    }
    await _reload(current, '${event.titles.length} pasos listos.', emit);
  }

  /// Vuelve a leer el tablero tras una acción; conserva el cronómetro.
  Future<void> _reload(
    FocusReady before,
    String message,
    Emitter<FocusState> emit, {
    String? Function()? proofStepId,
  }) async {
    final reloaded = await _getBoard(const NoParams());
    final latest = _latest(before);
    final board = reloaded.getOrElse((_) => latest.board);
    emit(
      latest.copyWith(
        board: board,
        busy: false,
        currentTaskId: () => board.session == null
            ? latest.currentTaskId
            : _nextTask(board.session!, latest.currentTaskId),
        gain: _gain(latest, board),
        message: message,
        proofStepId: proofStepId,
      ),
    );
  }

  /// XP ganada entre el tablero de [before] y [after]; null si no hubo.
  static FocusGain? _gain(FocusReady before, FocusBoard after) {
    final (old, now) = (before.board.progress, after.progress);
    if (old == null || now == null) return null;
    final xp = now.gainSince(old);
    if (xp <= 0) return null;
    return FocusGain(
      xp: xp,
      levelUp: now.level > old.level,
      seq: (before.gain?.seq ?? 0) + 1,
    );
  }

  static String? _clean(String? text) {
    final t = text?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  void _onIntentionChanged(
    FocusIntentionChanged event,
    Emitter<FocusState> emit,
  ) {
    final current = state;
    if (current is FocusReady) {
      emit(current.copyWith(intention: () => _clean(event.intention)));
    }
  }

  Future<void> _onNextScheduled(
    FocusNextScheduled event,
    Emitter<FocusState> emit,
  ) async {
    final current = state;
    if (current is! FocusReady || current.busy) return;
    emit(current.copyWith(busy: true, summary: current.summary));
    final result = await _schedule((taskId: event.taskId, at: event.at));
    final latest = _latest(current);
    emit(
      result.match(
        (failure) => latest.copyWith(
          busy: false,
          summary: current.summary,
          message: failure.message,
        ),
        (_) => latest.copyWith(
          busy: false,
          summary: current.summary,
          nextScheduledAt: event.at,
          message: 'Listo, quedó en tu agenda.',
        ),
      ),
    );
  }

  /// El estado actual si sigue listo (los tics lo avanzan mientras esperamos).
  FocusReady _latest(FocusReady fallback) =>
      state is FocusReady ? state as FocusReady : fallback;

  Future<void> _onEnded(FocusEnded event, Emitter<FocusState> emit) async {
    final current = state;
    final session = current is FocusReady ? current.board.session : null;
    if (current is! FocusReady || session == null || current.busy) return;
    emit(current.copyWith(busy: true));
    final ended = await _end(session.id);
    if (ended case Left(value: final failure)) {
      emit(_latest(current).copyWith(busy: false, message: failure.message));
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    final board = reloaded.getOrElse(
      (_) => FocusBoard(candidates: current.board.candidates),
    );
    // Las tareas como quedaron en la sesión; la semana ya la incluye.
    final summary = ended.getRight().toNullable()?.withStory(
      tasks: _latest(current).board.session?.tasks ?? session.tasks,
      weekMinutes: board.weekMinutes,
      prevWeekMinutes: board.prevWeekMinutes,
      distractions: _latest(current).distractions,
    );
    emit(_fresh(board, summary: summary));
  }

  void _onSummaryDismissed(
    FocusSummaryDismissed event,
    Emitter<FocusState> emit,
  ) {
    final current = state;
    if (current is FocusReady) emit(current.copyWith());
  }
}
