part of 'missions_bloc.dart';

sealed class MissionsEvent extends Equatable {
  const MissionsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar la pantalla Misiones.
class MissionsRequested extends MissionsEvent {
  const MissionsRequested();
}

/// El usuario guardó una misión nueva; [startFocus] abre luego la Mazmorra.
class MissionCreated extends MissionsEvent {
  const MissionCreated(this.mission, {this.startFocus = false});

  final NewMission mission;
  final bool startFocus;

  @override
  List<Object?> get props => [mission, startFocus];
}

/// El usuario marcó una misión como completada.
class MissionCompleted extends MissionsEvent {
  const MissionCompleted(this.missionId);

  final String missionId;

  @override
  List<Object?> get props => [missionId];
}

class MissionRenamed extends MissionsEvent {
  const MissionRenamed(this.missionId, this.title);

  final String missionId;
  final String title;

  @override
  List<Object?> get props => [missionId, title];
}

class MissionDeleted extends MissionsEvent {
  const MissionDeleted(this.missionId);

  final String missionId;

  @override
  List<Object?> get props => [missionId];
}
