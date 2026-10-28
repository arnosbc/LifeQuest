part of 'rpgenie_bloc.dart';

sealed class RpgenieEvent extends Equatable {
  const RpgenieEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar la Misión actual.
class RpgenieRequested extends RpgenieEvent {
  const RpgenieRequested();
}

/// "Ahora no": apartar la misión sin castigo.
class MissionSkipped extends RpgenieEvent {
  const MissionSkipped(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Volver a considerar las misiones apartadas.
class SkipsCleared extends RpgenieEvent {
  const SkipsCleared();
}

class CurrentMissionCompleted extends RpgenieEvent {
  const CurrentMissionCompleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}
