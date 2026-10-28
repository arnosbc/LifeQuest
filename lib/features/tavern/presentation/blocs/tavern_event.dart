part of 'tavern_bloc.dart';

sealed class TavernEvent extends Equatable {
  const TavernEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar la Taverna.
class TavernRequested extends TavernEvent {
  const TavernRequested();
}

class NpcCreated extends TavernEvent {
  const NpcCreated(this.npc);

  final NewNpc npc;

  @override
  List<Object?> get props => [npc];
}

class NpcMissionAccepted extends TavernEvent {
  const NpcMissionAccepted({required this.npcId, required this.title});

  final String npcId;
  final String title;

  @override
  List<Object?> get props => [npcId, title];
}

class NpcMissionCompleted extends TavernEvent {
  const NpcMissionCompleted({required this.npcId, required this.taskId});

  final String npcId;
  final String taskId;

  @override
  List<Object?> get props => [npcId, taskId];
}

class NpcRenamed extends TavernEvent {
  const NpcRenamed(this.npcId, this.name);

  final String npcId;
  final String name;

  @override
  List<Object?> get props => [npcId, name];
}

class NpcDeleted extends TavernEvent {
  const NpcDeleted(this.npcId);

  final String npcId;

  @override
  List<Object?> get props => [npcId];
}
