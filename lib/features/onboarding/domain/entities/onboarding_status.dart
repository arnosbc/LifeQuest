import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/core/entities/difficulty.dart';

export 'package:proyecto_movil/core/entities/difficulty.dart';

/// Si al jugador le toca el Onboarding y las dificultades para elegir.
class OnboardingStatus extends Equatable {
  const OnboardingStatus({required this.pending, required this.difficulties});

  final bool pending;
  final List<DifficultyOption> difficulties;

  @override
  List<Object?> get props => [pending, difficulties];
}
