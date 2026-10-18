import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

/// JSON tal como lo devuelve la RPC `profile_overview`.
const profileJson = <String, dynamic>{
  'display_name': 'Ana',
  'character_class': 'Estratega',
  'identity_statement': 'Una estratega que termina lo que empieza.',
  'level': 24,
  'current_xp': 7850,
  'xp_to_next_level': 12000,
  'coins': 2450,
  'hp_current': 80,
  'hp_max': 100,
  'is_weakened': false,
  'quests_completed': 38,
  'quests_failed': 12,
  'skill_limit': 6,
  'skills': [
    {
      'id': 's1',
      'name': 'Inglés',
      'level': 18,
      'current_xp': 50,
      'xp_to_next_level': 100,
    },
    {
      'id': 's2',
      'name': 'Salud',
      'level': 20,
      'current_xp': 10,
      'xp_to_next_level': 100,
    },
  ],
};

const englishSkill = Skill(
  id: 's1',
  name: 'Inglés',
  level: 18,
  currentXp: 50,
  xpToNextLevel: 100,
);

const profile = CharacterProfile(
  displayName: 'Ana',
  characterClass: 'Estratega',
  identityStatement: 'Una estratega que termina lo que empieza.',
  level: 24,
  currentXp: 7850,
  xpToNextLevel: 12000,
  coins: 2450,
  hpCurrent: 80,
  hpMax: 100,
  isWeakened: false,
  questsCompleted: 38,
  questsFailed: 12,
  skillLimit: 6,
  skills: [
    englishSkill,
    Skill(
      id: 's2',
      name: 'Salud',
      level: 20,
      currentXp: 10,
      xpToNextLevel: 100,
    ),
  ],
);

/// Héroe recién registrado.
const newProfile = CharacterProfile(
  level: 1,
  currentXp: 0,
  xpToNextLevel: 100,
  coins: 0,
  hpCurrent: 100,
  hpMax: 100,
  isWeakened: false,
  questsCompleted: 0,
  questsFailed: 0,
  skillLimit: 6,
  skills: [],
);
