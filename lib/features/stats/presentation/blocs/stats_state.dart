part of 'stats_bloc.dart';

sealed class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {
  const StatsInitial();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsSuccess extends StatsState {
  const StatsSuccess(this.board, {this.refreshing = false, this.message});

  final StatsBoard board;
  final bool refreshing;

  /// Aviso puntual (un refresco que falló).
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, message];
}

class StatsFailure extends StatsState {
  const StatsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
