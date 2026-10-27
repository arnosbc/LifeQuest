import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';

const difficulties = [
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

const pendingStatus = OnboardingStatus(
  pending: true,
  difficulties: difficulties,
);
