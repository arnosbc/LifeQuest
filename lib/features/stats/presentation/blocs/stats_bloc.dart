import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/features/stats/domain/entities/stats_board.dart';
import 'package:proyecto_movil/features/stats/domain/usecases/get_stats.dart';

part 'stats_event.dart';
part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc({required this._getStats, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const StatsInitial()) {
    on<StatsRequested>(_onRequested, transformer: droppable());
  }

  final GetStats _getStats;
  final DateTime Function() _clock;

  Future<void> _onRequested(
    StatsRequested event,
    Emitter<StatsState> emit,
  ) async {
    final current = state;
    emit(
      current is StatsSuccess
          ? StatsSuccess(current.board, refreshing: true)
          : const StatsLoading(),
    );
    final result = await _getStats(_clock());
    emit(
      result.match(
        (failure) => current is StatsSuccess
            ? StatsSuccess(current.board, message: failure.message)
            : StatsFailure(failure.message),
        StatsSuccess.new,
      ),
    );
  }
}
