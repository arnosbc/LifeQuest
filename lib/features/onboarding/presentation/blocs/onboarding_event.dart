part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Hay sesión: consulta si toca el Onboarding.
class OnboardingRequested extends OnboardingEvent {
  const OnboardingRequested();
}

/// Terminar o saltar: guarda lo elegido hasta ahora.
class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted(this.choices);

  final OnboardingChoices choices;

  @override
  List<Object?> get props => [choices];
}

/// Se cerró la sesión: la próxima cuenta se consulta de nuevo.
class OnboardingReset extends OnboardingEvent {
  const OnboardingReset();
}
