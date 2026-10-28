import 'package:equatable/equatable.dart';

/// La Taverna: NPCs del usuario, su límite (3 + Estandarte) y lo que cuesta
/// pedir una misión antes de tiempo.
class TavernBoard extends Equatable {
  const TavernBoard({
    this.npcs = const [],
    this.npcLimit = 3,
    this.instantCost = 15,
    this.coins = 0,
    this.skills = const [],
  });

  final List<Npc> npcs;
  final int npcLimit;
  final int instantCost;
  final int coins;
  final List<TavernSkill> skills;

  bool get full => npcs.length >= npcLimit;

  @override
  List<Object?> get props => [npcs, npcLimit, instantCost, coins, skills];
}

class Npc extends Equatable {
  const Npc({
    required this.id,
    required this.name,
    required this.skillName,
    this.frequency = NpcFrequency.weekly,
    this.nobleMission,
    this.freeAt,
    this.openMission,
    this.completed = 0,
  });

  final String id;
  final String name;

  /// Un NPC siempre tiene skill (CLAUDE.md §6).
  final String skillName;
  final NpcFrequency frequency;
  final String? nobleMission;

  /// Desde cuándo vuelve a ser gratis pedirle misión; null si ya lo es.
  final DateTime? freeAt;
  final NpcMission? openMission;

  /// Misiones cumplidas para este NPC.
  final int completed;

  bool isFree(DateTime now) => freeAt == null || !freeAt!.isAfter(now);

  @override
  List<Object?> get props => [
    id,
    name,
    skillName,
    frequency,
    nobleMission,
    freeAt,
    openMission,
    completed,
  ];
}

enum NpcFrequency { daily, weekly, monthly }

/// La misión es una tarea real (`tasks.source = 'npc'`).
class NpcMission extends Equatable {
  const NpcMission({required this.id, required this.title, this.xpReward = 0});

  final String id;
  final String title;
  final int xpReward;

  @override
  List<Object?> get props => [id, title, xpReward];
}

class TavernSkill extends Equatable {
  const TavernSkill({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class NewNpc extends Equatable {
  const NewNpc({
    required this.name,
    required this.skillId,
    this.frequency = NpcFrequency.weekly,
    this.nobleMission,
  });

  final String name;
  final String skillId;
  final NpcFrequency frequency;
  final String? nobleMission;

  @override
  List<Object?> get props => [name, skillId, frequency, nobleMission];
}
