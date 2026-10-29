import 'dart:typed_data';

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
    this.documents = const [],
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

  /// Documentos de contexto (p. ej. el plan de la asignatura) de los que
  /// RPGenie saca las misiones.
  final List<NpcDocument> documents;

  bool isFree(DateTime now) => freeAt == null || !freeAt!.isAfter(now);

  bool get documentsFull => documents.length >= NewNpcDocument.maxPerNpc;

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
    documents,
  ];
}

/// Documento de contexto ya resumido por RPGenie (`resources` con `npc_id`).
class NpcDocument extends Equatable {
  const NpcDocument({required this.id, required this.title});

  final String id;
  final String title;

  @override
  List<Object?> get props => [id, title];
}

/// Archivo elegido para adjuntar a un NPC.
class NewNpcDocument extends Equatable {
  const NewNpcDocument({
    required this.npcId,
    required this.fileName,
    required this.bytes,
  });

  /// Formatos que RPGenie sabe leer: PDF, Word y Markdown.
  static const extensions = ['pdf', 'docx', 'md', 'markdown'];

  /// Igual que el bucket `npc-context` (032).
  static const maxBytes = 10 * 1024 * 1024;

  /// Igual que add_npc_document (032).
  static const maxPerNpc = 3;

  final String npcId;
  final String fileName;
  final Uint8List bytes;

  /// Extensión en minúsculas, sin punto; vacía si no tiene.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  /// Nombre sin extensión, que se muestra como título.
  String get title {
    final dot = fileName.lastIndexOf('.');
    final name = (dot < 0 ? fileName : fileName.substring(0, dot)).trim();
    return name.length > 120 ? name.substring(0, 120) : name;
  }

  @override
  List<Object?> get props => [npcId, fileName, bytes.length];
}

enum NpcFrequency { daily, weekly, monthly }

/// La misión es una tarea real (`tasks.source = 'npc'`).
class NpcMission extends Equatable {
  const NpcMission({
    required this.id,
    required this.title,
    this.description,
    this.xpReward = 0,
  });

  final String id;
  final String title;

  /// Guía de RPGenie (objetivo, pasos o ejercicios y pistas); null si no hay.
  final String? description;
  final int xpReward;

  @override
  List<Object?> get props => [id, title, description, xpReward];
}

/// Lo que propone RPGenie: el título y, si pudo, la guía para cumplirla.
class NpcMissionSuggestion extends Equatable {
  const NpcMissionSuggestion({required this.title, this.guide});

  final String title;
  final String? guide;

  @override
  List<Object?> get props => [title, guide];
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
