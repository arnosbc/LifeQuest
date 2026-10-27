import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';

const settingsDifficulties = [
  DifficultyOption(
    level: GameDifficulty.easy,
    xpMultiplier: 1.2,
    hpPenaltyMultiplier: 0.75,
    coinMultiplier: 1,
  ),
  DifficultyOption(
    level: GameDifficulty.normal,
    xpMultiplier: 1,
    hpPenaltyMultiplier: 1,
    coinMultiplier: 1,
  ),
  DifficultyOption(
    level: GameDifficulty.hard,
    xpMultiplier: 0.85,
    hpPenaltyMultiplier: 1.25,
    coinMultiplier: 1,
  ),
];

const settingsOverview = SettingsOverview(
  level: 7,
  currentXp: 120,
  xpToNextLevel: 1852,
  settings: GameSettings(),
  difficulties: settingsDifficulties,
);
