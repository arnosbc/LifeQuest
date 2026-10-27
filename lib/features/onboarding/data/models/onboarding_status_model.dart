import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';

/// Respuesta de la RPC `onboarding_overview` (015_onboarding.sql).
class OnboardingStatusModel {
  const OnboardingStatusModel({
    required this.pending,
    required this.difficulties,
  });

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) =>
      OnboardingStatusModel(
        pending: json['pending'] as bool? ?? false,
        difficulties: [
          for (final d
              in (json['difficulties'] as List? ?? const [])
                  .cast<Map<String, dynamic>>())
            if (_level(d['level']) case final level?)
              DifficultyOption(
                level: level,
                xpMultiplier: (d['xp_multiplier'] as num).toDouble(),
                hpPenaltyMultiplier: (d['hp_penalty_multiplier'] as num)
                    .toDouble(),
                coinMultiplier: (d['coin_multiplier'] as num).toDouble(),
              ),
        ],
      );

  final bool pending;
  final List<DifficultyOption> difficulties;

  OnboardingStatus toEntity() =>
      OnboardingStatus(pending: pending, difficulties: difficulties);

  static GameDifficulty? _level(Object? name) =>
      GameDifficulty.values.where((d) => d.name == name).firstOrNull;
}
