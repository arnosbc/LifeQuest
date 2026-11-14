import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/challenges/domain/entities/challenges_board.dart';
import 'package:proyecto_movil/features/challenges/domain/usecases/claim_challenge.dart';
import 'package:proyecto_movil/features/challenges/domain/usecases/get_challenges.dart';

part 'challenges_event.dart';
part 'challenges_state.dart';

class ChallengesBloc extends Bloc<ChallengesEvent, ChallengesState> {
  ChallengesBloc({required this._getChallenges, required this._claimChallenge})
    : super(const ChallengesInitial()) {
    // droppable: toques repetidos mientras carga o cobra se ignoran.
    on<ChallengesRequested>(_onRequested, transformer: droppable());
    on<ChallengeClaimed>(_onClaimed, transformer: droppable());
  }

  final GetChallenges _getChallenges;
  final ClaimChallenge _claimChallenge;

  Future<void> _onRequested(
    ChallengesRequested event,
    Emitter<ChallengesState> emit,
  ) async {
    final current = state;
    emit(
      current is ChallengesSuccess
          ? ChallengesSuccess(current.board, refreshing: true)
          : const ChallengesLoading(),
    );
    final result = await _getChallenges(const NoParams());
    emit(
      result.match(
        (failure) => current is ChallengesSuccess
            ? ChallengesSuccess(current.board, message: failure.message)
            : ChallengesFailure(failure.message),
        ChallengesSuccess.new,
      ),
    );
  }

  Future<void> _onClaimed(
    ChallengeClaimed event,
    Emitter<ChallengesState> emit,
  ) async {
    final current = state;
    if (current is! ChallengesSuccess) return;
    emit(ChallengesSuccess(current.board, claimingKey: event.key));
    if (await _claimChallenge(event.key) case Left(value: final failure)) {
      emit(ChallengesSuccess(current.board, message: failure.message));
      return;
    }
    // El momento de recompensa del AppShell ya muestra las Monedas.
    final reloaded = await _getChallenges(const NoParams());
    emit(
      reloaded.match(
        (failure) => ChallengesSuccess(current.board, message: failure.message),
        ChallengesSuccess.new,
      ),
    );
  }
}
