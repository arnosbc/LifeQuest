import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/complete_good_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/create_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/delete_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/get_habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/register_bad_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/rename_habit.dart';

part 'habits_event.dart';
part 'habits_state.dart';

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  HabitsBloc({
    required this._getHabitsBoard,
    required this._createHabit,
    required this._completeGoodHabit,
    required this._registerBadHabit,
    required this._renameHabit,
    required this._deleteHabit,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const HabitsInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<HabitsRequested>(_onRequested, transformer: droppable());
    on<HabitCreated>(
      (event, emit) => _act(
        emit,
        (s) => HabitsSuccess(s.board, saving: true),
        () => _createHabit(event.habit),
        'Hábito creado. ¡Cada día cuenta!',
      ),
      transformer: droppable(),
    );
    on<GoodHabitCompleted>(
      (event, emit) => _act(
        emit,
        (s) => HabitsSuccess(s.board, busyHabitId: event.habitId),
        () => _completeGoodHabit(
          CompleteGoodHabitParams(habitId: event.habitId, now: _clock()),
        ),
        '¡Hábito cumplido! Tu racha sigue creciendo.',
      ),
      transformer: droppable(),
    );
    on<BadHabitRegistered>(
      (event, emit) => _act(
        emit,
        (s) => HabitsSuccess(s.board, busyHabitId: event.habitId),
        () => _registerBadHabit(event.habitId),
        'Registrado. Reconocerlo ya es avanzar.',
      ),
      transformer: droppable(),
    );
    on<HabitRenamed>(
      (event, emit) => _act(
        emit,
        (s) => HabitsSuccess(s.board, busyHabitId: event.habitId),
        () => _renameHabit(RenameParams(event.habitId, event.name)),
        'Hábito renombrado.',
      ),
      transformer: droppable(),
    );
    on<HabitDeleted>(
      (event, emit) => _act(
        emit,
        (s) => HabitsSuccess(s.board, busyHabitId: event.habitId),
        () => _deleteHabit(event.habitId),
        'Hábito borrado.',
      ),
      transformer: droppable(),
    );
  }

  final GetHabitsBoard _getHabitsBoard;
  final CreateHabit _createHabit;
  final CompleteGoodHabit _completeGoodHabit;
  final RegisterBadHabit _registerBadHabit;
  final RenameHabit _renameHabit;
  final DeleteHabit _deleteHabit;
  final DateTime Function() _clock;

  Future<void> _onRequested(
    HabitsRequested event,
    Emitter<HabitsState> emit,
  ) async {
    final current = state;
    emit(
      current is HabitsSuccess
          ? HabitsSuccess(current.board, refreshing: true)
          : const HabitsLoading(),
    );
    final result = await _getHabitsBoard(_clock());
    emit(
      result.match(
        (failure) => current is HabitsSuccess
            ? HabitsSuccess(current.board, message: failure.message)
            : HabitsFailure(failure.message),
        HabitsSuccess.new,
      ),
    );
  }

  /// Muestra [busy], ejecuta [action] y, si sale bien, vuelve a leer: XP,
  /// vida y rachas las calcula el servidor.
  Future<void> _act(
    Emitter<HabitsState> emit,
    HabitsSuccess Function(HabitsSuccess) busy,
    Future<Either<Failure, Unit>> Function() action,
    String message,
  ) async {
    final current = state;
    if (current is! HabitsSuccess) return;
    emit(busy(current));
    if (await action() case Left(value: final failure)) {
      emit(HabitsSuccess(current.board, message: failure.message));
      return;
    }
    final reloaded = await _getHabitsBoard(_clock());
    emit(
      reloaded.match(
        (failure) => HabitsSuccess(current.board, message: failure.message),
        (board) => HabitsSuccess(board, message: message),
      ),
    );
  }
}
