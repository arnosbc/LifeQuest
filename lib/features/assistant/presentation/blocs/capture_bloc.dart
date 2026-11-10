import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/resources/resource.dart';

import 'package:proyecto_movil/features/assistant/domain/entities/local_parser.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/break_down_task.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/interpret_capture.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/listen_voice.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/plan_goal.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/save_capture.dart';

part 'capture_event.dart';
part 'capture_state.dart';

/// Escribir → vista previa con chips → confirmar (o mandar a la Bandeja).
class CaptureBloc extends Bloc<CaptureEvent, CaptureState> {
  CaptureBloc({
    required this._interpret,
    required this._breakDown,
    required this._planGoal,
    required this._save,
    required this._listen,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const CaptureWriting()) {
    on<CaptureKindChanged>((event, _) => _kind = event.kind);
    on<CaptureListenRequested>(_onListen, transformer: droppable());
    on<CaptureListenStopped>((_, _) => _listen.stop());
    on<CaptureSubmitted>(_onSubmitted, transformer: droppable());
    on<CaptureDraftEdited>(_onEdited);
    on<CaptureBreakdownRequested>(_onBreakdown, transformer: droppable());
    on<CaptureAttachmentAdded>(_onAttachmentAdded);
    on<CaptureAttachmentRemoved>(_onAttachmentRemoved);
    on<CaptureConfirmed>(_onConfirmed, transformer: droppable());
    on<CaptureRestarted>((_, emit) => emit(const CaptureWriting()));
  }

  final InterpretCapture _interpret;
  final BreakDownTask _breakDown;
  final PlanGoal _planGoal;
  final DateTime Function() _clock;
  CaptureKind _kind = CaptureKind.task;
  final SaveCapture _save;
  final ListenVoice _listen;

  /// Dicta y, al terminar la frase, la interpreta como si se hubiera escrito.
  Future<void> _onListen(
    CaptureListenRequested event,
    Emitter<CaptureState> emit,
  ) async {
    if (state is! CaptureWriting) return;
    emit(const CaptureWriting(listening: true));
    var heard = '';
    String? error;
    await emit.forEach<String>(
      _listen(),
      onData: (text) {
        heard = text;
        return CaptureWriting(listening: true, heard: text);
      },
      onError: (e, _) {
        error = e is String ? e : 'No pude escucharte. Escribe la tarea.';
        return CaptureWriting(heard: heard, message: error);
      },
    );
    if (error != null) return;
    if (heard.trim().isEmpty) {
      emit(
        const CaptureWriting(
          message: 'No escuché nada. Inténtalo de nuevo o escríbelo.',
        ),
      );
      return;
    }
    await _onSubmitted(CaptureSubmitted(heard), emit);
  }

  Future<void> _onSubmitted(
    CaptureSubmitted event,
    Emitter<CaptureState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    emit(const CaptureWriting(busy: true));
    switch (_kind) {
      case CaptureKind.project:
        return _proposeProject(text, emit);
      case CaptureKind.goal:
        return _proposeGoal(text, emit);
      case CaptureKind.task:
        break;
    }
    final result = await _interpret(text);
    emit(
      result.match(
        (failure) => CaptureWriting(message: failure.message),
        (i) => CapturePreview(
          draft: i.draft,
          usedAi: i.usedAi,
          aiAvailable: i.aiAvailable,
          message: i.notice,
        ),
      ),
    );
  }

  /// Proyecto: título y fecha por reglas; la IA (si está) propone las tareas.
  Future<void> _proposeProject(String text, Emitter<CaptureState> emit) async {
    final parsed = LocalParser.parse(text, _clock());
    final draft = TaskDraft(
      title: parsed.title,
      dueDate: parsed.dueDate,
      priority: parsed.priority,
    );
    final steps = await _breakDown(draft);
    emit(
      CapturePreview(
        kind: CaptureKind.project,
        draft: draft,
        usedAi: steps.isRight(),
        aiAvailable: false,
        steps: steps.getOrElse((_) => const []),
        message: steps.match(
          (f) => '${f.message} Lo creo sin tareas; añádelas después.',
          (_) => null,
        ),
      ),
    );
  }

  /// Meta: necesita la IA para escribir el S.M.A.R.T.
  Future<void> _proposeGoal(String text, Emitter<CaptureState> emit) async {
    final result = await _planGoal(LocalParser.parse(text, _clock()));
    emit(
      result.match(
        (f) => CaptureWriting(
          message: '${f.message} También puedes usar el formulario.',
        ),
        (plan) => CapturePreview(
          kind: CaptureKind.goal,
          draft: plan.draft,
          smart: plan.smart,
          steps: plan.steps,
          usedAi: true,
          aiAvailable: false,
        ),
      ),
    );
  }

  void _onEdited(CaptureDraftEdited event, Emitter<CaptureState> emit) {
    if (state case final CapturePreview s) emit(s.copy(draft: event.draft));
  }

  Future<void> _onBreakdown(
    CaptureBreakdownRequested event,
    Emitter<CaptureState> emit,
  ) async {
    final current = state;
    if (current is! CapturePreview || current.busy) return;
    emit(current.copy(busy: true));
    final result = await _breakDown.withAttachments(
      current.draft,
      current.attachments,
    );
    emit(
      result.match(
        (failure) => current.copy(message: failure.message),
        (steps) => current.copy(steps: steps),
      ),
    );
  }

  void _onAttachmentAdded(
    CaptureAttachmentAdded event,
    Emitter<CaptureState> emit,
  ) {
    final s = state;
    if (s is! CapturePreview) return;
    if (event.draft.problem case final p?) return emit(s.copy(message: p));
    if (s.attachments.contains(event.draft)) return;
    emit(s.copy(attachments: [...s.attachments, event.draft]));
  }

  void _onAttachmentRemoved(
    CaptureAttachmentRemoved event,
    Emitter<CaptureState> emit,
  ) {
    if (state case final CapturePreview s) {
      emit(s.copy(attachments: [...s.attachments]..remove(event.draft)));
    }
  }

  Future<void> _onConfirmed(
    CaptureConfirmed event,
    Emitter<CaptureState> emit,
  ) async {
    final current = state;
    if (current is! CapturePreview || current.busy) return;
    emit(current.copy(busy: true));
    final toInbox =
        current.kind == CaptureKind.task &&
        (event.toInbox || current.draft.isNote);
    final saved = await _save((
      draft: current.draft,
      steps: current.steps,
      toInbox: toInbox,
      kind: current.kind,
      smart: current.smart,
      attachments: current.attachments,
    ));
    emit(
      saved.match(
        (failure) => current.copy(message: failure.message),
        (notice) => CaptureSaved(toInbox: toInbox, notice: notice),
      ),
    );
  }
}
