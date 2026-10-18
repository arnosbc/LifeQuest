import 'package:equatable/equatable.dart';

/// Área de vida creada por el usuario (Skill = Área de P.A.R.A.), sin tope de
/// nivel. El nivel y la XP solo los sube el servidor.
class Skill extends Equatable {
  const Skill({
    required this.id,
    required this.name,
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
  });

  final String id;
  final String name;
  final int level;
  final int currentXp;
  final int xpToNextLevel;

  /// Avance hacia el siguiente nivel, de 0 a 1.
  double get progress =>
      xpToNextLevel <= 0 ? 0 : (currentXp / xpToNextLevel).clamp(0, 1);

  @override
  List<Object?> get props => [id, name, level, currentXp, xpToNextLevel];
}

/// Perfil del Personaje: identidad, progreso, vitalidad y árbol de skills.
class CharacterProfile extends Equatable {
  const CharacterProfile({
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.coins,
    required this.hpCurrent,
    required this.hpMax,
    required this.isWeakened,
    required this.questsCompleted,
    required this.questsFailed,
    required this.skills,
    required this.skillLimit,
    this.displayName,
    this.characterClass,
    this.identityStatement,
  });

  final String? displayName;
  final String? characterClass;

  /// Respuesta a «¿Quién eres en este reino?».
  final String? identityStatement;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final int coins;
  final int hpCurrent;
  final int hpMax;
  final bool isWeakened;
  final int questsCompleted;
  final int questsFailed;
  final List<Skill> skills;

  /// Máximo de skills (6 por defecto, ampliable en Game Master).
  final int skillLimit;

  double get xpProgress =>
      xpToNextLevel <= 0 ? 0 : (currentXp / xpToNextLevel).clamp(0, 1);

  /// Misiones cumplidas sobre las cerradas; null si aún no hay ninguna.
  double? get completionRate {
    final total = questsCompleted + questsFailed;
    return total == 0 ? null : questsCompleted / total;
  }

  bool get canAddSkill => skills.length < skillLimit;

  @override
  List<Object?> get props => [
    displayName,
    characterClass,
    identityStatement,
    level,
    currentXp,
    xpToNextLevel,
    coins,
    hpCurrent,
    hpMax,
    isWeakened,
    questsCompleted,
    questsFailed,
    skills,
    skillLimit,
  ];
}
