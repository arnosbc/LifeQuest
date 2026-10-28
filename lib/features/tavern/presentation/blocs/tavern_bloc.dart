import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/accept_npc_mission.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/complete_npc_mission.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/create_npc.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/get_tavern_board.dart';

part 'tavern_event.dart';
part 'tavern_state.dart';

class TavernBloc extends Bloc<TavernEvent, TavernState> {
  TavernBloc({
    required this._getBoard,
    required this._createNpc,
    required this._acceptMission,
    required this._completeMission,
  }) : super(const TavernInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<TavernRequested>(_onRequested, transformer: droppable());
    on<NpcCreated>(
      (e, emit) => _act(
        emit,
        'new_npc',
        () => _createNpc(e.npc),
        '${e.npc.name} llegó a tu Taverna.',
      ),
      transformer: droppable(),
    );
    on<NpcMissionAccepted>(
      (e, emit) => _act(
        emit,
        e.npcId,
        () => _acceptMission(
          AcceptNpcMissionParams(npcId: e.npcId, title: e.title),
        ),
        'Misión aceptada. Ya está en tu Stage.',
      ),
      transformer: droppable(),
    );
    on<NpcMissionCompleted>(
      (e, emit) => _act(
        emit,
        e.npcId,
        () => _completeMission(e.taskId),
        '¡Misión cumplida! Tu NPC está orgulloso.',
      ),
      transformer: droppable(),
    );
  }

  final GetTavernBoard _getBoard;
  final CreateNpc _createNpc;
  final AcceptNpcMission _acceptMission;
  final CompleteNpcMission _completeMission;

  Future<void> _onRequested(
    TavernRequested event,
    Emitter<TavernState> emit,
  ) async {
    final current = state;
    emit(
      current is TavernSuccess
          ? TavernSuccess(current.board, refreshing: true)
          : const TavernLoading(),
    );
    final result = await _getBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is TavernSuccess
            ? TavernSuccess(current.board, message: failure.message)
            : TavernFailure(failure.message),
        TavernSuccess.new,
      ),
    );
  }

  /// Marca [busyKey], ejecuta [action] y, si sale bien, vuelve a leer.
  Future<void> _act(
    Emitter<TavernState> emit,
    String busyKey,
    Future<Either<Failure, Unit>> Function() action,
    String message,
  ) async {
    final current = state;
    if (current is! TavernSuccess) return;
    emit(TavernSuccess(current.board, busyKey: busyKey));
    if (await action() case Left(value: final failure)) {
      emit(TavernSuccess(current.board, message: failure.message));
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    emit(
      reloaded.match(
        (failure) => TavernSuccess(current.board, message: failure.message),
        (board) => TavernSuccess(board, message: message),
      ),
    );
  }
}
