import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Left;

import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/break_down_task.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/interpret_capture.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/save_capture.dart';

part 'capture_event.dart';
part 'capture_state.dart';

/// Escribir → vista previa con chips → confirmar (o mandar a la Bandeja).
class CaptureBloc extends Bloc<CaptureEvent, CaptureState> {
  CaptureBloc({
    required this._interpret,
    required this._breakDown,
    required this._save,
  }) : super(const CaptureWriting()) {
    on<CaptureSubmitted>(_onSubmitted, transformer: droppable());
    on<CaptureDraftEdited>(_onEdited);
    on<CaptureBreakdownRequested>(_onBreakdown, transformer: droppable());
    on<CaptureConfirmed>(_onConfirmed, transformer: droppable());
    on<CaptureRestarted>((_, emit) => emit(const CaptureWriting()));
  }

  final InterpretCapture _interpret;
  final BreakDownTask _breakDown;
  final SaveCapture _save;

  Future<void> _onSubmitted(
    CaptureSubmitted event,
    Emitter<CaptureState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    emit(const CaptureWriting(busy: true));
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
    final result = await _breakDown(current.draft);
    emit(
      result.match(
        (failure) => current.copy(message: failure.message),
        (steps) => current.copy(steps: steps),
      ),
    );
  }

  Future<void> _onConfirmed(
    CaptureConfirmed event,
    Emitter<CaptureState> emit,
  ) async {
    final current = state;
    if (current is! CapturePreview || current.busy) return;
    emit(current.copy(busy: true));
    final toInbox = event.toInbox || current.draft.isNote;
    final saved = await _save((
      draft: current.draft,
      steps: current.steps,
      toInbox: toInbox,
    ));
    if (saved case Left(value: final failure)) {
      emit(current.copy(message: failure.message));
      return;
    }
    emit(CaptureSaved(toInbox: toInbox));
  }
}
