import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Left;

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/domain/entities/new_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/complete_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/create_mission.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/get_missions_board.dart';

part 'missions_event.dart';
part 'missions_state.dart';

class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  MissionsBloc({
    required this._getMissionsBoard,
    required this._createMission,
    required this._completeMission,
  }) : super(const MissionsInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<MissionsRequested>(_onRequested, transformer: droppable());
    on<MissionCreated>(_onCreated, transformer: droppable());
    on<MissionCompleted>(_onCompleted, transformer: droppable());
  }

  final GetMissionsBoard _getMissionsBoard;
  final CreateMission _createMission;
  final CompleteMission _completeMission;

  Future<void> _onRequested(
    MissionsRequested event,
    Emitter<MissionsState> emit,
  ) async {
    final current = state;
    emit(
      current is MissionsSuccess
          ? MissionsSuccess(current.board, refreshing: true)
          : const MissionsLoading(),
    );
    final result = await _getMissionsBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is MissionsSuccess
            ? MissionsSuccess(current.board, message: failure.message)
            : MissionsFailure(failure.message),
        MissionsSuccess.new,
      ),
    );
  }

  Future<void> _onCreated(
    MissionCreated event,
    Emitter<MissionsState> emit,
  ) async {
    final current = state;
    if (current is! MissionsSuccess) return;
    emit(MissionsSuccess(current.board, saving: true));
    final created = await _createMission(event.mission);
    if (created case Left(value: final failure)) {
      emit(MissionsSuccess(current.board, message: failure.message));
      return;
    }
    await _reload(
      emit,
      current.board,
      event.startFocus
          ? 'Misión creada. ¡Tu sesión de enfoque te espera!'
          : 'Misión creada. ¡Un paso más hacia tu objetivo!',
      focusRequested: event.startFocus,
    );
  }

  Future<void> _onCompleted(
    MissionCompleted event,
    Emitter<MissionsState> emit,
  ) async {
    final current = state;
    if (current is! MissionsSuccess) return;
    emit(MissionsSuccess(current.board, busyMissionId: event.missionId));
    final completed = await _completeMission(event.missionId);
    if (completed case Left(value: final failure)) {
      emit(MissionsSuccess(current.board, message: failure.message));
      return;
    }
    await _reload(
      emit,
      current.board,
      '¡Misión completada! Tu héroe se hace más fuerte.',
    );
  }

  /// XP, Monedas y orden los decide el servidor: se vuelven a leer.
  Future<void> _reload(
    Emitter<MissionsState> emit,
    MissionsBoard previous,
    String message, {
    bool focusRequested = false,
  }) async {
    final reloaded = await _getMissionsBoard(const NoParams());
    emit(
      reloaded.match(
        (failure) => MissionsSuccess(previous, message: failure.message),
        (board) => MissionsSuccess(
          board,
          message: message,
          focusRequested: focusRequested,
        ),
      ),
    );
  }
}
