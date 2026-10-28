import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';
import 'package:proyecto_movil/features/vision/domain/usecases/get_vision_board.dart';
import 'package:proyecto_movil/features/vision/domain/usecases/save_vision.dart';
import 'package:proyecto_movil/features/vision/domain/usecases/set_vision_link.dart';

part 'vision_event.dart';
part 'vision_state.dart';

class VisionBloc extends Bloc<VisionEvent, VisionState> {
  VisionBloc({
    required this._getBoard,
    required this._save,
    required this._setLink,
  }) : super(const VisionInitial()) {
    on<VisionRequested>(_onRequested, transformer: droppable());
    on<VisionSaved>(
      (e, emit) => _act(
        emit,
        'save',
        () => _save(e.content),
        'Tu visión quedó guardada.',
      ),
      transformer: droppable(),
    );
    on<VisionLinkToggled>(
      (e, emit) => _act(
        emit,
        e.item.id,
        () => _setLink(VisionLinkParams(e.item, linked: e.linked)),
        e.linked ? 'Ahora sirve a tu visión.' : 'Desvinculado de tu visión.',
      ),
      transformer: droppable(),
    );
  }

  final GetVisionBoard _getBoard;
  final SaveVision _save;
  final SetVisionLink _setLink;

  Future<void> _onRequested(
    VisionRequested event,
    Emitter<VisionState> emit,
  ) async {
    final current = state;
    emit(
      current is VisionSuccess
          ? VisionSuccess(current.board, refreshing: true)
          : const VisionLoading(),
    );
    final result = await _getBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is VisionSuccess
            ? VisionSuccess(current.board, message: failure.message)
            : VisionFailure(failure.message),
        VisionSuccess.new,
      ),
    );
  }

  Future<void> _act(
    Emitter<VisionState> emit,
    String busyKey,
    Future<Either<Failure, Unit>> Function() action,
    String message,
  ) async {
    final current = state;
    if (current is! VisionSuccess) return;
    emit(VisionSuccess(current.board, busyKey: busyKey));
    if (await action() case Left(value: final failure)) {
      emit(VisionSuccess(current.board, message: failure.message));
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    emit(
      reloaded.match(
        (failure) => VisionSuccess(current.board, message: failure.message),
        (board) => VisionSuccess(board, message: message),
      ),
    );
  }
}
