part of 'stats_bloc.dart';

sealed class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar las Estadísticas.
class StatsRequested extends StatsEvent {
  const StatsRequested();
}
