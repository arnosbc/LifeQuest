import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Left;

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/domain/usecases/claim_daily_chest.dart';
import 'package:proyecto_movil/features/home/domain/usecases/complete_habit.dart';
import 'package:proyecto_movil/features/home/domain/usecases/get_home_dashboard.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getHomeDashboard,
    required this._completeHabit,
    required this._claimDailyChest,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const HomeInitial()) {
    // droppable: toques repetidos mientras carga se ignoran.
    on<HomeRequested>(_onRequested, transformer: droppable());
    on<HomeHabitCompleted>(_onHabitCompleted, transformer: droppable());
    on<HomeChestClaimed>(_onChestClaimed, transformer: droppable());
  }

  final GetHomeDashboard _getHomeDashboard;
  final CompleteHabit _completeHabit;
  final ClaimDailyChest _claimDailyChest;
  final DateTime Function() _clock;

  Future<void> _onRequested(
    HomeRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    emit(
      current is HomeSuccess
          ? HomeSuccess(current.dashboard, refreshing: true)
          : const HomeLoading(),
    );
    final result = await _getHomeDashboard(_clock());
    emit(
      result.match(
        (failure) => current is HomeSuccess
            ? HomeSuccess(current.dashboard, message: failure.message)
            : HomeFailure(failure.message),
        HomeSuccess.new,
      ),
    );
  }

  Future<void> _onHabitCompleted(
    HomeHabitCompleted event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeSuccess) return;
    emit(HomeSuccess(current.dashboard, busyHabitId: event.habitId));

    final now = _clock();
    final completed = await _completeHabit(
      CompleteHabitParams(habitId: event.habitId, now: now),
    );
    if (completed case Left(value: final failure)) {
      emit(HomeSuccess(current.dashboard, message: failure.message));
      return;
    }
    // XP, Monedas y racha los calcula el servidor: se vuelven a leer.
    final reloaded = await _getHomeDashboard(now);
    emit(
      reloaded.match(
        (failure) => HomeSuccess(current.dashboard, message: failure.message),
        HomeSuccess.new,
      ),
    );
  }

  Future<void> _onChestClaimed(
    HomeChestClaimed event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeSuccess) return;
    emit(HomeSuccess(current.dashboard, claimingChest: true));
    if (await _claimDailyChest(const NoParams()) case Left(
      value: final failure,
    )) {
      emit(HomeSuccess(current.dashboard, message: failure.message));
      return;
    }
    final reloaded = await _getHomeDashboard(_clock());
    final coins = current.dashboard.chest.coins;
    emit(
      reloaded.match(
        (failure) => HomeSuccess(current.dashboard, message: failure.message),
        (dashboard) =>
            HomeSuccess(dashboard, message: '¡Cofre abierto! +$coins Monedas.'),
      ),
    );
  }
}
