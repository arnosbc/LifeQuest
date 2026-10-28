import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/features/rpgenie/domain/entities/current_mission.dart';
import 'package:proyecto_movil/features/rpgenie/domain/usecases/complete_current_mission.dart';
import 'package:proyecto_movil/features/rpgenie/domain/usecases/get_current_mission.dart';

part 'rpgenie_event.dart';
part 'rpgenie_state.dart';

class RpgenieBloc extends Bloc<RpgenieEvent, RpgenieState> {
  RpgenieBloc({required this._getMission, required this._completeMission})
    : super(const RpgenieInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<RpgenieRequested>(
      (e, emit) => _load(emit, refreshing: true),
      transformer: droppable(),
    );
    on<MissionSkipped>((e, emit) {
      // "Ahora no" no castiga: solo la aparta mientras dure la pantalla.
      _skipped.add(e.taskId);
      return _load(emit, message: 'Entendido. Te propongo otra.');
    }, transformer: droppable());
    on<SkipsCleared>((e, emit) {
      _skipped.clear();
      return _load(emit);
    }, transformer: droppable());
    on<CurrentMissionCompleted>(_onCompleted, transformer: droppable());
  }

  final GetCurrentMission _getMission;
  final CompleteCurrentMission _completeMission;
  final List<String> _skipped = [];

  Future<void> _load(
    Emitter<RpgenieState> emit, {
    bool refreshing = false,
    String? message,
  }) async {
    final current = state;
    emit(
      current is RpgenieSuccess
          ? RpgenieSuccess(current.board, refreshing: refreshing, busy: true)
          : const RpgenieLoading(),
    );
    final result = await _getMission(List.of(_skipped));
    emit(
      result.match(
        (failure) => current is RpgenieSuccess
            ? RpgenieSuccess(current.board, message: failure.message)
            : RpgenieFailure(failure.message),
        (board) => RpgenieSuccess(board, message: message),
      ),
    );
  }

  Future<void> _onCompleted(
    CurrentMissionCompleted event,
    Emitter<RpgenieState> emit,
  ) async {
    final current = state;
    if (current is! RpgenieSuccess) return;
    emit(RpgenieSuccess(current.board, busy: true));
    final result = await _completeMission(event.taskId);
    await result.match(
      (failure) async =>
          emit(RpgenieSuccess(current.board, message: failure.message)),
      (_) => _load(emit, message: '¡Misión cumplida! Aquí va la siguiente.'),
    );
  }
}
