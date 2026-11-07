import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';

/// Lo que el jugador eligió al terminar o saltar. Textos vacíos = sin elegir.
class OnboardingChoices extends Equatable {
  const OnboardingChoices({
    this.identity = '',
    this.skill = '',
    this.difficulty = GameDifficulty.normal,
    this.aiEnabled = false,
  });

  static const identityMaxLength = 280;
  static const skillMaxLength = 40;

  final String identity;
  final String skill;
  final GameDifficulty difficulty;

  /// Encender el asistente con IA (Gemini) desde el principio.
  final bool aiEnabled;

  /// Mismos límites que el Perfil y la BD (002).
  bool get isValid =>
      identity.trim().length <= identityMaxLength &&
      skill.trim().length <= skillMaxLength;

  @override
  List<Object?> get props => [identity, skill, difficulty, aiEnabled];
}
