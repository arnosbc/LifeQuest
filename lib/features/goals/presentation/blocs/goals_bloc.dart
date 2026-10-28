import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';
import 'package:proyecto_movil/features/goals/domain/usecases/archive_goal.dart';
import 'package:proyecto_movil/features/goals/domain/usecases/attack_boss.dart';
import 'package:proyecto_movil/features/goals/domain/usecases/get_goals_board.dart';

part 'goals_event.dart';
part 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsBloc({
    required this._getBoard,
    required this._attack,
    required this._archive,
  }) : super(const GoalsInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<GoalsRequested>(_onRequested, transformer: droppable());
    on<BossAttacked>(
      (e, emit) => _act(
        emit,
        e.attack.id,
        () => _attack(e.attack),
        (board) => _defeated(board, e.goalId)
            ? '¡Victoria! Venciste al jefe: '
                  '+${board.victoryXp} XP y +${board.victoryCoins} Monedas.'
            : '¡Golpe certero! −${e.attack.damage} de vida al jefe.',
      ),
      transformer: droppable(),
    );
    on<GoalArchived>(
      (e, emit) => _act(
        emit,
        e.goalId,
        () => _archive(e.goalId),
        (_) => 'Meta archivada. Tu XP sigue contigo.',
      ),
      transformer: droppable(),
    );
  }

  final GetGoalsBoard _getBoard;
  final AttackBoss _attack;
  final ArchiveGoal _archive;

  static bool _defeated(GoalsBoard board, String goalId) => board.goals.any(
    (g) => g.id == goalId && g.status == GoalStatus.completed,
  );

  Future<void> _onRequested(
    GoalsRequested event,
    Emitter<GoalsState> emit,
  ) async {
    final current = state;
    emit(
      current is GoalsSuccess
          ? GoalsSuccess(current.board, refreshing: true)
          : const GoalsLoading(),
    );
    final result = await _getBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is GoalsSuccess
            ? GoalsSuccess(current.board, message: failure.message)
            : GoalsFailure(failure.message),
        GoalsSuccess.new,
      ),
    );
  }

  /// Marca [busyKey], ejecuta [action] y, si sale bien, vuelve a leer: la
  /// vida del jefe y la victoria las calcula el servidor.
  Future<void> _act(
    Emitter<GoalsState> emit,
    String busyKey,
    Future<Either<Failure, Unit>> Function() action,
    String Function(GoalsBoard board) message,
  ) async {
    final current = state;
    if (current is! GoalsSuccess) return;
    emit(GoalsSuccess(current.board, busyKey: busyKey));
    if (await action() case Left(value: final failure)) {
      emit(GoalsSuccess(current.board, message: failure.message));
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    emit(
      reloaded.match(
        (failure) => GoalsSuccess(current.board, message: failure.message),
        (board) => GoalsSuccess(board, message: message(board)),
      ),
    );
  }
}
