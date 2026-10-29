import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/capture_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/convert_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/convert_thought_to_goal.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/delete_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/file_thought.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/get_brain_dump.dart';

part 'brain_dump_event.dart';
part 'brain_dump_state.dart';

class BrainDumpBloc extends Bloc<BrainDumpEvent, BrainDumpState> {
  BrainDumpBloc({
    required this._getBoard,
    required this._capture,
    required this._file,
    required this._convert,
    required this._delete,
    required this._convertToGoal,
  }) : super(const BrainDumpInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<BrainDumpRequested>(_onRequested, transformer: droppable());
    on<ThoughtCaptured>(
      (e, emit) => _act(
        emit,
        'capture',
        () => _capture(e.content),
        'Guardado. Tu mente queda libre.',
      ),
      transformer: droppable(),
    );
    on<ThoughtFiled>(
      (e, emit) => _act(
        emit,
        e.thoughtId,
        () => _file(FileThoughtParams(e.thoughtId, e.shelf)),
        switch (e.shelf) {
          ThoughtShelf.someday => 'Guardada en Algún día.',
          ThoughtShelf.reference => 'Guardada como Referencia.',
          ThoughtShelf.pending => 'De vuelta en la bandeja.',
        },
      ),
      transformer: droppable(),
    );
    on<ThoughtConverted>(
      (e, emit) => _act(
        emit,
        e.conversion.thoughtId,
        () => _convert(e.conversion),
        switch (e.conversion.kind) {
          ThoughtKind.task => 'Misión creada. Ya está en tu Stage.',
          ThoughtKind.done => '¡Hecho en un momento! Una menos.',
          ThoughtKind.delegated => 'Delegada. Queda pendiente en tu Stage.',
          ThoughtKind.project => 'Proyecto creado en tu Stage.',
        },
      ),
      transformer: droppable(),
    );
    on<ThoughtConvertedToGoal>(
      (e, emit) => _act(
        emit,
        e.conversion.thoughtId,
        () => _convertToGoal(e.conversion),
        '¡Meta creada! Ya te espera como jefe en tu Stage.',
      ),
      transformer: droppable(),
    );
    on<ThoughtDeleted>(
      (e, emit) =>
          _act(emit, e.thoughtId, () => _delete(e.thoughtId), 'Idea borrada.'),
      transformer: droppable(),
    );
  }

  final GetBrainDump _getBoard;
  final CaptureThought _capture;
  final FileThought _file;
  final ConvertThought _convert;
  final DeleteThought _delete;
  final ConvertThoughtToGoal _convertToGoal;

  Future<void> _onRequested(
    BrainDumpRequested event,
    Emitter<BrainDumpState> emit,
  ) async {
    final current = state;
    emit(
      current is BrainDumpSuccess
          ? BrainDumpSuccess(current.board, refreshing: true)
          : const BrainDumpLoading(),
    );
    final result = await _getBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is BrainDumpSuccess
            ? BrainDumpSuccess(current.board, message: failure.message)
            : BrainDumpFailure(failure.message),
        BrainDumpSuccess.new,
      ),
    );
  }

  /// Marca [busyKey], ejecuta [action] y, si sale bien, vuelve a leer.
  Future<void> _act(
    Emitter<BrainDumpState> emit,
    String busyKey,
    Future<Either<Failure, Unit>> Function() action,
    String message,
  ) async {
    final current = state;
    if (current is! BrainDumpSuccess) return;
    emit(BrainDumpSuccess(current.board, busyKey: busyKey));
    if (await action() case Left(value: final failure)) {
      emit(BrainDumpSuccess(current.board, message: failure.message));
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    emit(
      reloaded.match(
        (failure) => BrainDumpSuccess(current.board, message: failure.message),
        (board) => BrainDumpSuccess(board, message: message),
      ),
    );
  }
}
